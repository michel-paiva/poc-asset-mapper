<?php

Deployer\remove('shared_dirs', ['var/cache']);

Deployer\task(
    'yw:pimcore-skeleton:create-db-if-not-exists',
    function () {
        $command = sprintf(
            '{{release_path}}/docker/create-db-if-not-exists.sh -h "%s" -d "%s" -u "%s" -p "%s"',
            '`grep "mysql_hostname=" "{{remote_file_credentials_mysql}}" | cut -d= -f 2`',
            '`grep "mysql_database=" "{{remote_file_credentials_mysql}}" | cut -d= -f 2`',
            '`grep "mysql_user=" "{{remote_file_credentials_mysql}}" | cut -d= -f 2`',
            '`grep "mysql_password=" "{{remote_file_credentials_mysql}}" | cut -d= -f 2`'
        );
        \Deployer\writeln(\Deployer\run($command));
    }
)->desc('Create database table if not exists yet.');

\Deployer\before('deploy:pimcore:classes_rebuild:delete', 'yw:pimcore-skeleton:create-db-if-not-exists');

Deployer\task(
    'yw:pimcore-skeleton:run-migrations',
    function () {
        $command = '{{release_path}}/bin/console pimcore:migrations:migrate --set carpetright --no-interaction';
        \Deployer\writeln(\Deployer\run($command));
    }
)->desc('Run migrations.');

\Deployer\after('deploy:pimcore:classes_rebuild:delete', 'yw:pimcore-skeleton:run-migrations');

$jobFactory = function (
    string $name,
    string $command,
    string $minute,
    string $hour = '*',
    array $environments = [
        \Deployer\STAGE_ACCEPTANCE,
        \Deployer\STAGE_DEVELOPMENT,
        \Deployer\STAGE_PRODUCTION,
        \Deployer\STAGE_TEST
    ]
) {
    $logFileName = preg_replace('//', $name, '-');
    while (strpos($logFileName, '--') !== false) {
        $logFileName = str_replace('--', '-', $logFileName);
    }
    $logFileName = trim($logFileName, '-');

    return new \Youwe\Deployer\Cron\Job(
        $name,
        new \Youwe\Deployer\Cron\Expression($minute, $hour, '*', '*', '*'),
        sprintf('{{release_path}}/%s', $command),
        '',
        sprintf('{{release_path}}/var/logs/cronjob-%s.log', $logFileName),
        $environments
    );
};

$searchBackendReindexCron = function (string $minute, string $hour, array $environments) use ($jobFactory) {
    return $jobFactory(
        'Reindex Backend Search',
        'bin/console pimcore:search-backend-reindex',
        $minute,
        $hour,
        $environments
    );
};

\Youwe\Deployer\Cron\Job::$logFilePrefix = '&>>';
\Deployer\add(
    'crontab_injection_jobs',
    [
        $jobFactory('Process Incoming Import Data', 'bin/console b2bimportflow:process-incoming-import-data', '*'),
        $jobFactory('Process Queued Import Data', 'bin/console b2bimportflow:process-queued-import-data', '*'),
        $jobFactory('Download data from FTP', 'bin/console ftp:download-all-files', '0'),
        $jobFactory('Pimcore Maintenance', 'bin/console maintenance', '*/5'),
        $searchBackendReindexCron('0', '2', [\Deployer\STAGE_ACCEPTANCE]),
        $searchBackendReindexCron('20', '2', [\Deployer\STAGE_DEVELOPMENT]),
        $searchBackendReindexCron('40', '2', [\Deployer\STAGE_PRODUCTION]),
        $searchBackendReindexCron('0', '3', [\Deployer\STAGE_TEST]),
    ]
);

<?php

namespace AppBundle\EventListener;

use Pimcore\Bundle\AdminBundle\EventListener\CsrfProtectionListener;
use Symfony\Component\HttpFoundation\Request;
/**
 * The only purpose of this class is to disable Csrf protection because it was
 * causing an unexpected behaviour on form validations, disabling it is not ideal
 * but might be solved in the future by pimcore
 */
class DisableCsrfProtectionListener extends CsrfProtectionListener
{
    /**
     * Disabling Csrf protection, because it was causing an unexpected errors on form validations
     *
     * @param Request $request
     */
    public function checkCsrfToken(Request $request)
    {
        return true;
    }
}
<?php


namespace Youwe\ImageMapperBundle\EventListener;

use Pimcore\Event\Model\AssetEvent;
use Pimcore\Model\DataObject\Data\Hotspotimage;
use Pimcore\Model\DataObject\Product;
use Symfony\Component\DependencyInjection\ContainerInterface;

class MapNewAssetListener
{
    private $container;
    public function __construct(ContainerInterface $container)
    {
        $this->container = $container;
    }

    public function onPostAdd(AssetEvent $event)
    {
        $asset = $event->getAsset();

        $path = $asset->getFullPath();

        if (!preg_match('/^\/mapper\/.+\/.+\/.+$/', $path)) {
            return;
        }

        $splitted = explode('/', $path);

        $class = $splitted[2];
        $field = $splitted[3];
        $ids = $splitted[4];

        $fullClass = "\Pimcore\Model\DataObject\\" . $class;

        if (!class_exists($fullClass)) {
            return;
        }

        $getters = $this->container->getParameter('image_mapper.getters');

        $methodGetter = array_reduce($getters, function($curr, $item) use ($class){
            if (!$curr && isset($item[$class])) {
                return $item[$class];
            }
            return $curr;
        });

        if (!$methodGetter) {
            return;
        }

        $setterTypes = $this->container->getParameter('image_mapper.set_types');

        $setter = array_reduce($setterTypes, function($curr, $item) use ($field){
            if (!$curr && isset($item[$field])) {
                return $item[$field];
            }
            return $curr;
        });

        $idList = explode(',', $ids);

        foreach ($idList as $id) {
            $idClean = trim($id);

            if (!$idClean) {
                continue;
            }

            $obj = call_user_func_array([$fullClass, $methodGetter], [$id, 1]);

            if (!$obj) {
                continue;
            }

            switch($setter) {
                case 'gallery':
                    $this->setGallery($obj, $field, $asset);
                    break;
                case 'asset':
                    $this->setAsset($obj, $field, $asset);
                    break;
                default:
                    return;
            }
        }
    }

    private function setAsset($obj, $field, \Pimcore\Model\Asset $asset)
    {
        $method = 'set'.$field;

        if (!method_exists($obj, $method)) {
            return;
        }

        call_user_func_array([$obj, $method],[$asset]);

        $obj->save();
    }

    private function setGallery($obj, $field, \Pimcore\Model\Asset $asset)
    {
        $method = 'set'.$field;
        if (!method_exists($obj, $method)) {
            return;
        }
        $methodGet = 'get'.$field;
        if (!method_exists($obj, $methodGet)) {
            return;
        }

        $gallery = call_user_func_array([$obj, $methodGet],[$asset]);

        $items = $gallery->getItems() ?? [];

        array_push($items, new Hotspotimage($asset));

        call_user_func_array([$obj, $method], [$items]);
    }
}

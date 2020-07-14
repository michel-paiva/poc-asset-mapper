<?php

namespace Youwe\ImageMapperBundle;

use Pimcore\Extension\Bundle\AbstractPimcoreBundle;

class ImageMapperBundle extends AbstractPimcoreBundle
{
    public function getJsPaths()
    {
        return [
            '/bundles/imagemapper/js/pimcore/startup.js'
        ];
    }
}
<?php

namespace AppBundle\Controller;

use Pimcore\Controller\FrontendController;
use Symfony\Component\HttpFoundation\Request;

class DefaultController extends FrontendController
{
    public function defaultAction(Request $request)
    {
        if (!$this->editmode) {
            return $this->redirect('/admin');
        }
    }
}

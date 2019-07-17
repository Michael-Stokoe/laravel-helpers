<?php

class IsAppInDev {
    public function execute()
    {
        return app()->environment(['local', 'dev']);
    }
}

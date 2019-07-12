<?php

class EnvHelper {
    public function execute()
    {
        return app()->environment(['local', 'dev']);
    }
}

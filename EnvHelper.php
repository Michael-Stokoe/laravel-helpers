<?php

class EnvHelper {
    public static function execute()
    {
        return app()->environment(['local', 'dev']);
    }
}

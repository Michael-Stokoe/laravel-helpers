<?php

namespace App\Console\Commands;

use Log;
use Illuminate\Support\Arr;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Storage;

class FileSystemsTest extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'filesystems:test
        { --filesystem= : Specific file system to test. Must match a file system name given in config/filesystems.php }
    ';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Tests connections to given filesystems.';

    /**
     * Skip connection tests for these filesystems.
     *
     * @var array
     */
    protected $fileSystemsToSkip = [
        's3',
        'local',
        'public',
    ];

    protected $aConnectionHasFailed = false;

    /**
     * Create a new command instance.
     *
     * @return void
     */
    public function __construct()
    {
        parent::__construct();
    }

    /**
     * Execute the console command.
     *
     * @return mixed
     */
    public function handle()
    {
        // Check if the user has defined a filesystem to test.
        $specificFileSystem = $this->option('filesystem');

        if ($specificFileSystem) {
            // Test the specific file system and done.
            $result = $this->testFileSystem($specificFileSystem);

            return $result;
        }

        // Get the configured file systems from config/filesystems.php and filter out the exclusions defined above.
        $fileSystems = array_keys(config('filesystems.disks'));
        $fileSystems = array_diff($fileSystems, $this->fileSystemsToSkip);
        $toTest = implode(', ', $fileSystems);
        $skipped = implode(', ', $this->fileSystemsToSkip);

        $this->logInfo("Testing connection to file systems: [$toTest]. (Skipped: [$skipped])");

        foreach ($fileSystems as $fileSystem) {
            $result = $this->testFileSystem($fileSystem);

            if (!$result) {
                $this->aConnectionHasFailed = true;

                continue;
            }
        }

        if ($this->aConnectionHasFailed) {
            $this->logError('A connection failed. Please check the log for more information.');
            return false;
        }

        return true;
    }

    /**
     * Opens connection to given file system. Returns true/false based on result.
     *
     * @param string $fileSystem
     * @return boolean
     */
    public function testFileSystem(string $fileSystem)
    {
        $this->logInfo("Testing connection to [$fileSystem]...");

        try {
            Storage::disk($fileSystem)->files();
        } catch (\Exception $exception) {
            // Connecting to the remote FS threw an exception.
            $msg = $exception->getMessage();
            $this->logError("[ERROR] Connecting to file system: [$fileSystem] failed. Error message:");
            $this->logError($msg);

            return false;
        }

        $this->logInfo("[SUCCESS] Connected to [$fileSystem].");

        return true;
    }

    /**
     * Writes to logs and console output
     *
     * @param string $message
     * @return void
     */
    public function logInfo(string $message)
    {
        $this->info($message);
        Log::info($message);
    }

    /**
     * Writes error to log and console output.
     *
     * @param string $message
     * @return void
     */
    public function logError(string $message)
    {
        $this->info($message);
        Log::error($message);
    }
}

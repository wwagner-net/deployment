<?php

declare(strict_types=1);

namespace Deployer;

// Include base recipes
require 'recipe/common.php';
require 'contrib/cachetool.php';
require 'contrib/rsync.php';

// Include hosts
import('.hosts.yml');

set('http_user', 'pXXXXXX');
set('http_group', 'users');

set('/usr/local/bin/php', 'php');
set('bin/typo3', '{{release_path}}/vendor/bin/typo3');

// Set maximum number of releases
set('keep_releases', 5);

// Since updating the ReferenceIndex takes a very long time for some projects, this value must be increased.
set('default_timeout', 1200); // 20 minutes instead of the standard 5 minutes

// Set TYPO3 docroot
set('typo3_webroot', 'public');

// Set shared directories
$sharedDirectories = [
    '{{typo3_webroot}}/fileadmin',
    '{{typo3_webroot}}/typo3temp',
];
set('shared_dirs', $sharedDirectories);

// Set shared files
$sharedFiles = [
    'config/system/additional.php',
];
set('shared_files', $sharedFiles);

// Define all rsync excludes
$exclude = [
    // OS specific files
    '.DS_Store',
    'Thumbs.db',
    // Project specific files and directories
    '.ddev',
    '.editorconfig',
    '.fleet',
    '.git*',
    '.idea',
    '.php-cs-fixer.dist.php',
    '.vscode',
    'auth.json',
    'deploy.php',
    '.hosts.yml',
    '.gitlab-ci.yml',
    'phpstan.neon',
    'phpunit.xml',
    'README*',
    'rector.php',
    'typoscript-lint.yml',
    '/.deployment',
    '/var',
    '/**/Tests/*',
    'dbv13.sql',
    'fileadmin.tar.gz',
    'README.md',
    'fetchdatabase.sh',
    'renovate.json',
    // Node.js / Playwright files
    'node_modules',
    'package.json',
    'package-lock.json',
    'playwright.config.ts',
    '/tests/',
    '/test-results/',
    '/playwright-report/',
    '/blob-report/',
    '/playwright/.cache/',
    'npm-debug.log*',
    // GitHub Actions
    '.github',
    // CLAUDE.md (development documentation)
    'CLAUDE.md'
];

// Define rsync options
set('rsync', [
    'exclude' => array_merge($sharedDirectories, $sharedFiles, $exclude),
    'exclude-file' => false,
    'include' => [],
    'include-file' => false,
    'filter' => [],
    'filter-file' => false,
    'filter-perdir' => false,
    'flags' => 'az',
    'options' => ['delete'],
    'timeout' => 300,
]);
set('rsync_src', './');

// Use rsync to update code during deployment
task('deploy:update_code', function () {
    invoke('rsync:warmup');
    invoke('rsync');
});

// TYPO3 tasks

desc('Make database dump');
task(
    'typo3:database:export', function () {
    // Zeitstempel erzeugen, z. B. 20250113-101530
    $timestamp = date('Ymd-His');
    // Den Dateinamen entsprechend anpassen
    $dumpFile = "dbbackup-{$timestamp}.sql";

    // Datenbank-Export in den Shared-Folder schreiben
    run("{{bin/typo3}} database:export > {{deploy_path}}/shared/{$dumpFile}");
}
);
desc('Flush page caches');
task('typo3:cache_flush', function () {
    run('{{bin/typo3}} cache:flush -g pages');
});

desc('Warm up caches');
task('typo3:cache_warmup', function () {
    run('{{bin/typo3}} cache:warmup');
});

desc('Set up all installed extensions');
task('typo3:extension_setup', function () {
    run('{{bin/typo3}} extension:setup');
});

desc('Fix folder structure');
task('typo3:fix_folder_structure', function () {
    run('{{bin/typo3}} install:fixfolderstructure');
});

desc('Update language files');
task('typo3:language_update', function () {
    run('{{bin/typo3}} language:update');
});

desc('Update database schema');
task('typo3:update_database', function () {
    run("{{bin/typo3}} database:updateschema '*.add,*.change'");
});

desc('Update reference index');
task('typo3:update_reference_index', function () {
    run("{{bin/typo3}} referenceindex:update");
});

desc('Execute upgrade wizards');
task('typo3:upgrade_all', function () {
    run('{{bin/typo3}} upgrade:prepare');
    run('{{bin/typo3}} upgrade:run all --confirm all');
});

task('correct_permissions', function () {
    run('find {{release_path}} -type d -not -path "{{release_path}}/vendor/bin*" -print0 | xargs -0 chmod 0755');
    run('find {{release_path}} -type f -not -path "{{release_path}}/vendor/bin*" -print0 | xargs -0 chmod 0644');
});

// Register TYPO3 tasks
before('deploy:symlink', function () {
    // 1. Backup-Operationen
    invoke('typo3:database:export');

    // 2. Strukturelle Änderungen
    invoke('typo3:fix_folder_structure');
    invoke('correct_permissions');

    // 3. Extensions und Datenbank
    invoke('typo3:extension_setup');
    invoke('typo3:update_database');

    // 5. Datenoperationen
    invoke('typo3:update_reference_index');
    invoke('typo3:language_update');

    // 6. Cache-Operationen vor dem Symlink
    invoke('typo3:cache_warmup');
});

after('deploy:symlink', function () {
    // Cache-Operationen nach dem Symlink
    invoke('typo3:cache_flush');
});

// Main deployment task
desc('Deploy TYPO3 project');
task('deploy', [
    'deploy:prepare',
    'deploy:publish',
]);

// Unlock on failed deployment
after('deploy:failed', 'deploy:unlock');

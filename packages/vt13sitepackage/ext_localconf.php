<?php

defined('TYPO3') or die();

$GLOBALS['TYPO3_CONF_VARS']['RTE']['Presets']['myproject'] = 'EXT:vt13sitepackage/Configuration/RTE/myproject.yaml';

$GLOBALS['TYPO3_CONF_VARS']['MAIL']['layoutRootPaths'][100] = 'EXT:vt13sitepackage/Resources/Private/Extensions/core/Layouts/';

$GLOBALS['TYPO3_CONF_VARS']['EXTENSIONS']['backend']['loginLogo'] = 'EXT:vt13sitepackage/Resources/Public/img/innovatech_logo_green.svg';
$GLOBALS['TYPO3_CONF_VARS']['EXTENSIONS']['backend']['loginHighlightColor'] = '#8bb83b';

$GLOBALS['TYPO3_CONF_VARS']['SYS']['passwordPolicies'] = [
    'myproject' => [
        'validators' => [
            \TYPO3\CMS\Core\PasswordPolicy\Validator\CorePasswordValidator::class => [
                'options' => [
                    'digitCharacterRequired' => true,
                    'lowerCaseCharacterRequired' => true,
                    'minimumLength' => 20,
                    'specialCharacterRequired' => true,
                    'upperCaseCharacterRequired' => true
                ]
            ]
        ]
    ],
];

$GLOBALS['TYPO3_CONF_VARS']['BE']['passwordPolicy'] = 'myproject';
$GLOBALS['TYPO3_CONF_VARS']['FE']['passwordPolicy'] = 'myproject';

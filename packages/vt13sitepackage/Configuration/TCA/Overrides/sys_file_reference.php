<?php

defined('TYPO3') or die();

// Basic configuration for the allowedAspectRatios
$allowedAspectRatios = [
    'NaN' => [
        'title' => 'Free',
        'value' => 0.0,
    ],
    '16:9' => [
        'title' => '16:9',
        'value' => 16 / 9,
    ],
    '4:3' => [
        'title' => '4:3',
        'value' => 4 / 3,
    ],
    '4:5' => [
        'title' => '4:5 (Instagram)',
        'value' => 4 / 5,
    ],
    '1:1' => [
        'title' => '1:1',
        'value' => 1 / 1,
    ],
];

// Function for creating the configuration for each variant
function createCropVariantConfig($title, $allowedAspectRatios) {
    return [
        'title' => $title,
        'allowedAspectRatios' => $allowedAspectRatios,
    ];
}

// Use the createCropVariantConfig function to create the configuration for each variant

$GLOBALS['TCA']['sys_file_reference']['columns']['crop']['config']['cropVariants'] = [
    'default' => createCropVariantConfig('Large Desktop', $allowedAspectRatios),
    'desktop' => createCropVariantConfig('Desktop', $allowedAspectRatios),
    'tablet' => createCropVariantConfig('Tablet', $allowedAspectRatios),
    'smartphone' => createCropVariantConfig('Smartphone', $allowedAspectRatios),
];

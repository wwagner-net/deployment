<?php

\TYPO3\CMS\Core\Utility\GeneralUtility::makeInstance(\B13\Container\Tca\Registry::class)->configureContainer(
    (
    new \B13\Container\Tca\ContainerConfiguration(
        '2cols', // CType
        '2 Column Container', // label
        '50% / 50%', // description
        [
            [
                ['name' => 'Linke Spalte', 'colPos' => 100],
                ['name' => 'Rechte Spalte', 'colPos' => 200]
            ]
        ] // grid configuration
    )
    )
        // set an optional icon configuration
        ->setIcon('EXT:container/Resources/Public/Icons/container-2col.svg')
);

\TYPO3\CMS\Core\Utility\GeneralUtility::makeInstance(\B13\Container\Tca\Registry::class)->configureContainer(
    (
    new \B13\Container\Tca\ContainerConfiguration(
        '3cols', // CType
        '3 Column Container', // label
        '33% / 33% / 33%', // description
        [
            [
                ['name' => 'Linke Spalte', 'colPos' => 100],
                ['name' => 'Mittlere Spalte', 'colPos' => 200],
                ['name' => 'Rechte Spalte', 'colPos' => 300]
            ]
        ] // grid configuration
    )
    )
        // set an optional icon configuration
        ->setIcon('EXT:container/Resources/Public/Icons/container-3col.svg')
);

\TYPO3\CMS\Core\Utility\GeneralUtility::makeInstance(\B13\Container\Tca\Registry::class)->configureContainer(
    (
    new \B13\Container\Tca\ContainerConfiguration(
        '4cols', // CType
        '4 Column Container', // label
        '25% / 25% / 25% / 25%', // description
        [
            [
                ['name' => 'Linke Spalte', 'colPos' => 100],
                ['name' => 'Linke Mittlere Spalte', 'colPos' => 200],
                ['name' => 'Linke Rechte Spalte', 'colPos' => 300],
                ['name' => 'Rechte Spalte', 'colPos' => 400]
            ]
        ] // grid configuration
    )
    )
        // set an optional icon configuration
        ->setIcon('EXT:container/Resources/Public/Icons/container-4col.svg')
);

\TYPO3\CMS\Core\Utility\GeneralUtility::makeInstance(\B13\Container\Tca\Registry::class)->configureContainer(
    (
    new \B13\Container\Tca\ContainerConfiguration(
        '2cols-left', // CType
        '2 Column Container 66% / 33%', // label
        '66% / 33%', // description
        [
            [
                ['name' => 'Linke Spalte', 'colPos' => 100, 'colspan' => 2],
                ['name' => 'Rechte Spalte', 'colPos' => 200, 'colspan' => 1]
            ]
        ] // grid configuration
    )
    )
        // set an optional icon configuration
        ->setIcon('EXT:container/Resources/Public/Icons/container-2col-left.svg')
);

\TYPO3\CMS\Core\Utility\GeneralUtility::makeInstance(\B13\Container\Tca\Registry::class)->configureContainer(
    (
    new \B13\Container\Tca\ContainerConfiguration(
        '2cols-right', // CType
        '2 Column Container 33% / 66%', // label
        '33% / 66%', // description
        [
            [
                ['name' => 'Linke Spalte', 'colPos' => 100, 'colspan' => 1],
                ['name' => 'Rechte Spalte', 'colPos' => 200, 'colspan' => 2]
            ]
        ] // grid configuration
    )
    )
        // set an optional icon configuration
        ->setIcon('EXT:container/Resources/Public/Icons/container-2col-right.svg')
);

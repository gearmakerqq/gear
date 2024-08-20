// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./gearsTypesV1.sol";
import "./Trigonometry.sol";

// code to generate the SVG taking the 36 colors as input
contract gearsMetadataUtils {
    using Strings for uint256;
    using Strings for uint8;
    using Strings for int256;
    using SafeMath for uint256;
    using SafeMath for uint8;

    //prettier-ignore
    uint8[] public spiralKey = [21, 15, 16, 22, 28, 27, 26, 20, 14, 8, 9, 10, 11, 17, 23, 29, 35, 34, 33, 32, 31, 25, 19, 13, 7, 1, 2, 3, 4, 5, 6, 12, 18, 24, 30, 36];
    string public basePart1 =
        "<svg xmlns='http://www.w3.org/2000/svg' version='1.2' viewBox='-1.3 -1.3 8.6 8.6' shape-rendering='crispEdges' width='100%' height='100%'><g transform='rotate(-45 3 3)'>";
    string public basePart2 = "</g></svg>";
    string[] public colorMap = [
        "cyan",
        "magenta",
        "yellow",
        "black",
        "white",
        "transparent"
    ];

    function generateSVG(uint256 tokenId) public view returns (string memory) {
        string memory svgContent = basePart1;
        for (uint i = 0; i < 36; i++) {
            uint spiralIndex = spiralKey[i] - 1;
            uint colorIndex = (tokenId / 10 ** (36 - i - 1)) % 10;

            string memory x = (spiralIndex % 6).toString();
            string memory y = (spiralIndex / 6).toString();

            string memory rectangle = string(
                abi.encodePacked(
                    "'<rect id='",
                    (spiralIndex + 1).toString(),
                    "' fill='",
                    colorMap[colorIndex - 1],
                    "' x='",
                    x,
                    "' y='",
                    y,
                    "' width='1' height='1'></rect>"
                )
            );
            svgContent = string(abi.encodePacked(svgContent, rectangle));
        }
        svgContent = string(abi.encodePacked(svgContent, basePart2));
        return svgContent;
    }

    function generateTokenURI(
        uint256 tokenId,
        gearsInfo memory gearsObj
    ) public view returns (string memory) {
        uint256 paddedId = handlePadding(tokenId);
        uint8[6] memory digitCounts = getDigitCounts(paddedId);
        averageHSL(digitCounts);
        // Get the length of the tokenId in bytes
        uint256 tokenIdLength = bytes(tokenId.toString()).length;
        uint256 level = 37 - tokenIdLength;

        // Calculate the grid size based on the tokenIdLength
        string memory gridSize;
        string memory viewBox;
        if (tokenIdLength == 1) {
            gridSize = '1x1';
            viewBox = '2.28 2.98 1.45 1.45';
        } else if (tokenIdLength >= 2 && tokenIdLength <= 4) {
            gridSize = '2x2';
            viewBox = '1.55 1.7 2.9 2.6';
        } else if (tokenIdLength >= 5 && tokenIdLength <= 9) {
            gridSize = '3x3';
            viewBox = '0.85 1.55 4.3 4.3';
        } else if (tokenIdLength >= 10 && tokenIdLength <= 16) {
            gridSize = '4x4';
            viewBox = '0.1 0.1 5.8 5.8';
        } else if (tokenIdLength >= 17 && tokenIdLength <= 25) {
            gridSize = '5x5';
            viewBox = '-.58 0.1 7.2 7.2';
        } else {
            gridSize = '6x6';
            viewBox = '-1.3 -1.3 8.6 8.6';
        }

        string memory xn_str;
        if (keccak256(abi.encodePacked(gearsObj.xnVersion)) == keccak256(abi.encodePacked('a'))) {
            // do something here...
            xn_str = gearsObj.xn.toString();
        } else {
            xn_str = string.concat(gearsObj.xn.toString(), "-", gearsObj.xnVersion);
        }

        bytes memory dataURI = abi.encodePacked(
            "{",
            '"name": "xn-',
            xn_str,
            '",',
            '"description": "',
            gearsObj.description,
            '",', // add 'title' if there from the local memory
            '"image": "data:image/svg+xml;utf8,',
            generateSVG(paddedId),
            '",',
            '"background_color": "F9F1EC",',
            '"external_url": "https://gears.com/view?id=',
            tokenId.toString(),
            '",', // TODO URL - to be finalized before launch
            '"attributes": [',
            '{"trait_type": "level", "value": "',
            level.toString(),   
            '"},',
            '{"trait_type": "grid", "value": "',
            gridSize,   
            '"},',
            '{"trait_type": "view", "value": "',
            viewBox,   
            '"},',
            // '{"trait_type": "message", "value": "',
            // gearsObj.description,
            // '"},',
            '{"trait_type": "creator", "value": "',
            Strings.toHexString(gearsObj.creator),
            '"},',
            '{"trait_type": "composite color", "value": "',
            averageHSL(digitCounts),
            '"},',
            '{"trait_type": "1-cyan", "value": ',
            digitCounts[0].toString(),
            ',"max_value": 36},',
            '{"trait_type": "2-magenta", "value": ',
            digitCounts[1].toString(),
            ', "max_value": 36},',
            '{"trait_type": "3-yellow", "value": ',
            digitCounts[2].toString(),
            ', "max_value": 36},',
            '{"trait_type": "4-black", "value": ',
            digitCounts[3].toString(),
            ', "max_value": 36},',
            '{"trait_type": "5-white", "value": ',
            digitCounts[4].toString(),
            ', "max_value": 36},',
            '{"trait_type": "6-transparent", "value": ',
            digitCounts[5].toString(),
            ', "max_value": 36}'
            "]",
            "}"
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(dataURI)
                )
            );
    }

    function handlePadding(uint256 tokenId) public pure returns (uint256) {
        //get number of digits
        uint8 numDigits = 0;
        uint256 temp = tokenId;
        while (temp != 0) {
            numDigits++;
            temp /= 10;
        }
        //add 6's as padding for anyting lass than 36 digits
        uint256 paddedId = tokenId;
        uint8 padding = 36 - numDigits;
        for (uint8 i = 0; i < padding; i++) {
            paddedId = paddedId * 10 + 6;
        }
        return paddedId;
    }

    //get array of digit value counts
    function getDigitCounts(
        uint256 gearPattern
    ) public pure returns (uint8[6] memory) {
        uint8[6] memory digitCounts;
        for (uint8 i = 0; i < 36; i++) {
            // Get the i-th digit of gearPattern
            uint256 digit = (gearPattern / (10 ** i)) % 10;
            digitCounts[digit - 1] += 1;
        }
        return digitCounts;
    }

    function getColorHSL(
        string memory color
    ) public pure returns (uint256 h, uint256 s, uint256 l) {
        if (keccak256(abi.encodePacked(color)) == keccak256("cyan")) {
            return (uint256(180), uint256(100), uint256(50));
        } else if (keccak256(abi.encodePacked(color)) == keccak256("magenta")) {
            return (uint256(300), uint256(100), uint256(50));
        } else if (keccak256(abi.encodePacked(color)) == keccak256("yellow")) {
            return (uint256(60), uint256(100), uint256(50));
        } else if (keccak256(abi.encodePacked(color)) == keccak256("black")) {
            return (uint256(0), uint256(0), uint256(0));
        } else if (keccak256(abi.encodePacked(color)) == keccak256("white")) {
            return (uint256(0), uint256(0), uint256(100));
        } else if (
            keccak256(abi.encodePacked(color)) == keccak256("transparent")
        ) {
            return (uint256(0), uint256(0), uint256(0));
        } else {
            return (uint256(0), uint256(0), uint256(0));
        }
    }

    // Function to calculate the average HSL value
    function averageHSL(
        uint8[6] memory digitCounts
    ) public view returns (string memory) {
        uint256 coloredCells = digitCounts[0] +
            digitCounts[1] +
            digitCounts[2] +
            digitCounts[3] +
            digitCounts[4];
        uint256 totalCells = coloredCells;
        uint256 valueCap = totalCells * 100;

        int256 avgHueSin = 0;
        int256 avgHueCos = 0;
        uint256 avgSat = 0;
        uint256 avgLight = 0;

        for (uint8 i = 0; i < 5; i++) {
            (uint256 h, uint256 s, uint256 l) = getColorHSL(colorMap[i]);

            int256 weight = int256(uint(digitCounts[i]));
            avgHueSin += int256(
                weight * Trigonometry.sin((h * 2 * Trigonometry.PI) / 360)
            );
            avgHueCos += int256(
                weight * Trigonometry.cos((h * 2 * Trigonometry.PI) / 360)
            );
            avgSat += s * uint256(weight);
            avgLight += l * uint256(weight);
        }

        uint256 avgHue;
        int hueSigned = (Trigonometry.atan2(avgHueSin, avgHueCos) * 360) /
            int256(2 * Trigonometry.PI);
        if (hueSigned < 0) {
            avgHue = uint256(360) - uint256(Trigonometry.abs(hueSigned));
        } else {
            avgHue = uint256(hueSigned);
        }
        avgHue = (avgHue + 360) % 360;

        avgSat = ((avgSat) * 100) / (valueCap);
        avgLight = ((avgLight) * 100) / (valueCap);

        string memory hslString = string(
            abi.encodePacked(
                "hsl(",
                avgHue.toString(),
                ", ",
                avgSat.toString(),
                "%, ",
                avgLight.toString(),
                "%)"
            )
        );
        return hslString;
    }
}
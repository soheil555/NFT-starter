// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC721URIStorage} from '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import {ERC721} from '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import {Base64} from '@openzeppelin/contracts/utils/Base64.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {VRFV2WrapperConsumerBase} from '@chainlink/contracts/src/v0.8/vrf/VRFV2WrapperConsumerBase.sol';

contract NFT is ERC721URIStorage, VRFV2WrapperConsumerBase, Ownable {
    event NFTMintRequested(uint256 requestId, uint256 tokenId);
    event NFTMinted(uint256 tokenId, uint256 randomNumber);
    event TokenURISet(uint256 tokenId);

    uint256 private nextTokenId = 0;
    uint32 private callbackGasLimit = 300000;
    uint8 private requestConfirmations = 3;
    uint8 private numRandomWords = 1;
    uint256 private maxNumberOfPaths = 10;
    uint256 private maxNumberOfPathCommands = 10;
    uint256 private size = 400;
    string[6] private colors = [
        '#0F1035',
        '#365486',
        '#7FC7D9',
        '#DCF2F1',
        '#92C7CF',
        '#AAD7D9'
    ];

    mapping(uint256 => address) public requestIdToSender;
    mapping(uint256 => uint256) public requestIdToTokenId;
    mapping(uint256 => uint256) public tokenIdToRandomNumber;

    constructor(
        address _link,
        address _vrfV2Wrapper
    )
        ERC721('NFT', 'NFT')
        VRFV2WrapperConsumerBase(_link, _vrfV2Wrapper)
        Ownable(msg.sender)
    {}

    function requestMint() public {
        uint256 requestId = requestRandomness(
            callbackGasLimit,
            requestConfirmations,
            numRandomWords
        );

        requestIdToSender[requestId] = msg.sender;
        uint256 tokenId = nextTokenId;
        requestIdToTokenId[requestId] = tokenId;

        nextTokenId++;

        emit NFTMintRequested(requestId, tokenId);
    }

    function setTokenURI(uint256 tokenId) public {
        require(
            bytes(tokenURI(tokenId)).length == 0,
            'TokenURI already set for this tokenId'
        );
        require(
            nextTokenId > tokenId,
            'Token has not been minted yet; tokenId is invalid'
        );
        uint256 randomNumber = tokenIdToRandomNumber[tokenId];
        require(
            randomNumber > 0,
            'Wait for the Chainlink node to provide a random number'
        );

        string memory svg = generateSVG(randomNumber);
        _setTokenURI(tokenId, formatTokenURI(svg));

        emit TokenURISet(tokenId);
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        address nftOwner = requestIdToSender[_requestId];
        uint256 tokenId = requestIdToTokenId[_requestId];
        uint256 randomNumber = _randomWords[0];
        _safeMint(nftOwner, tokenId);
        tokenIdToRandomNumber[tokenId] = randomNumber;

        emit NFTMinted(tokenId, randomNumber);
    }

    function generateSVG(
        uint256 _randomNumber
    ) private view returns (string memory svg) {
        uint256 numberOfPaths = (_randomNumber % maxNumberOfPaths) + 1;
        svg = string(
            abi.encodePacked(
                "<svg xmlns='http://www.w3.org/2000/svg' height='",
                Strings.toString(size),
                "' width='",
                Strings.toString(size),
                "'>"
            )
        );
        for (uint i = 0; i < numberOfPaths; i++) {
            string memory path = generatePath(
                uint256(keccak256(abi.encodePacked(_randomNumber, i)))
            );
            svg = string(abi.encodePacked(svg, path));
        }
        svg = string(abi.encodePacked(svg, '</svg>'));
    }

    function generatePath(
        uint256 _randomNumber
    ) private view returns (string memory path) {
        uint256 numberOfPathCommands = (_randomNumber %
            maxNumberOfPathCommands) + 1;
        path = "<path d='";
        for (uint i = 0; i < numberOfPathCommands; i++) {
            string memory command = i % 2 == 0 ? 'M' : 'L';
            string memory pathCommand = generatePathCommand(
                uint256(keccak256(abi.encodePacked(_randomNumber, size + i))),
                command
            );
            path = string(abi.encodePacked(path, pathCommand, ' '));
        }
        string memory color = colors[_randomNumber % colors.length];
        path = string(
            abi.encodePacked(
                path,
                "' fill='transparent' stroke='",
                color,
                "'/>"
            )
        );
    }

    function generatePathCommand(
        uint256 _randomNumber,
        string memory _command
    ) private view returns (string memory pathCommand) {
        uint256 parameterOne = uint256(
            keccak256(abi.encodePacked(_randomNumber, size * 2))
        ) % size;
        uint256 parameterTwo = uint256(
            keccak256(abi.encodePacked(_randomNumber, size * 2 + 1))
        ) % size;
        pathCommand = string(
            abi.encodePacked(
                _command,
                ' ',
                Strings.toString(parameterOne),
                ' ',
                Strings.toString(parameterTwo)
            )
        );
    }

    function formatTokenURI(
        string memory _svg
    ) public pure returns (string memory tokenURI) {
        bytes memory imageURI = abi.encodePacked(
            'data:image/svg+xml;base64,',
            Base64.encode(bytes(_svg))
        );

        tokenURI = string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    abi.encodePacked(
                        '{"name": "SVG NFT", "description": "SVG NFT", "image": "',
                        imageURI,
                        '"}'
                    )
                )
            )
        );
    }
}

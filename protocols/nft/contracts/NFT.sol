// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC721URIStorage} from '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import {ERC721} from '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import {Base64} from '@openzeppelin/contracts/utils/Base64.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {VRFV2WrapperConsumerBase} from '@chainlink/contracts/src/v0.8/vrf/VRFV2WrapperConsumerBase.sol';

contract NFT is ERC721URIStorage, VRFV2WrapperConsumerBase, Ownable {
    uint256 private _nextTokenId;
    event CreatedNTF(uint256 indexed tokenId, string tokenURI);

    constructor(
        address _link,
        address _vrfV2Wrapper
    )
        ERC721('NFT', 'NFT')
        VRFV2WrapperConsumerBase(_link, _vrfV2Wrapper)
        Ownable(msg.sender)
    {}

    function create(string memory _svg) public {
        _safeMint(msg.sender, _nextTokenId);
        string memory tokenURI = formatTokenURI(_svg);
        _setTokenURI(_nextTokenId, tokenURI);

        emit CreatedNTF(_nextTokenId, tokenURI);

        _nextTokenId++;
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

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {}
}

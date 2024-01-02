// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC721URIStorage} from '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import {ERC721} from '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import {Base64} from '@openzeppelin/contracts/utils/Base64.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {VRFV2WrapperConsumerBase} from '@chainlink/contracts/src/v0.8/vrf/VRFV2WrapperConsumerBase.sol';

contract NFT is ERC721URIStorage, VRFV2WrapperConsumerBase, Ownable {
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(
        uint256 requestId,
        uint256[] randomWords,
        uint256 payment
    );

    uint256 private _nextTokenId = 0;
    uint32 private callbackGasLimit = 300000;
    uint8 private requestConfirmations = 3;
    uint8 private numRandomWords = 1;
    uint256[] public requestIds;
    uint256 public lastRequestId;

    struct RequestStatus {
        uint256 paid;
        bool fulfilled;
        uint256[] randomWords;
    }
    mapping(uint256 => RequestStatus) public s_requests;

    constructor(
        address _link,
        address _vrfV2Wrapper
    )
        ERC721('NFT', 'NFT')
        VRFV2WrapperConsumerBase(_link, _vrfV2Wrapper)
        Ownable(msg.sender)
    {}

    function create() public {
        uint256 requestId = requestRandomness(
            callbackGasLimit,
            requestConfirmations,
            numRandomWords
        );

        s_requests[requestId] = RequestStatus({
            paid: VRF_V2_WRAPPER.calculateRequestPrice(callbackGasLimit),
            fulfilled: false,
            randomWords: new uint256[](0)
        });
        requestIds.push(requestId);
        lastRequestId = requestId;

        emit RequestSent(requestId, numRandomWords);
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(s_requests[_requestId].paid > 0, 'request not found');
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        emit RequestFulfilled(
            _requestId,
            _randomWords,
            s_requests[_requestId].paid
        );
    }

    function getRequestStatus(
        uint256 _requestId
    )
        external
        view
        returns (uint256 paid, bool fulfilled, uint256[] memory randomWords)
    {
        require(s_requests[_requestId].paid > 0, 'request not found');
        RequestStatus memory request = s_requests[_requestId];
        return (request.paid, request.fulfilled, request.randomWords);
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

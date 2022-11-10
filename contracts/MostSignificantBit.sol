pragma solidity 0.8.7;
import "hardhat/console.sol";

contract MostSignificantBit {

    function loop (uint _x, uint8 _ctr, uint8 _target) private view returns(uint x, uint8 ctr, uint8 target){

            console.log("START: loop variables input | counter | target", _x, _ctr, _target);

            while(_ctr >= 1){
                // number > 128 bit integer value
                bool isGreater = _x >= 2 ** _ctr;
                console.log("is greater than value", isGreater);

                if( isGreater){
                    _x >>= _ctr;
                    _target += _ctr;        
                }

                _ctr = _ctr / 2;
                
                console.log("END: loop variables input | counter | target", _x, _ctr, _target);
                (_x, _ctr, _target) = loop(_x, _ctr, _target);

            }
            return (_x, _ctr, _target);
    }
    function findMostSignificantBit(uint x) external view returns (uint8 r) {
        // Code
        (, , r) = loop(x, 128, 0);

    }
}
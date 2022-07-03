%lang starknet
%builtins pedersen range_check ecdsa

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.uint256 import ( Uint256, uint256_add, uint256_sub)

from starkware.cairo.common.math import (
    assert_not_zero, assert_not_equal, assert_lt
)
from starkware.starknet.common.syscalls import get_caller_address

from contracts.token.ERC721.ERC721_base import (
    ERC721_name, ERC721_symbol, ERC721_balanceOf, ERC721_ownerOf, ERC721_getApproved,
    ERC721_isApprovedForAll, ERC721_mint, ERC721_burn, ERC721_initializer, ERC721_approve,
    ERC721_setApprovalForAll, ERC721_transferFrom, ERC721_safeTransferFrom, _exists)

# ERC721_sex, ERC721_legs, ERC721_wings, Do not need these imports with new Declare animal function. Otherwise, specify sex in constructor when deploying.
# name = 0x646F67676F (doggo)
# symbol = 0x444F47474F (DOGGO)
# Use to convert https://www.rapidtables.com/convert/number/ascii-to-hex.html

#
# Data structures
#

struct Animal:
    member sex: felt
    member legs: felt
    member wings: felt
end


#
# Constants
#

const REGISTRATION_PRICE = 20


#
# Storage
#

@storage_var
func next_token_id() -> (next_token_id: felt):
end

@storage_var
func animals(token_id: felt) -> (animal: Animal):
end

@storage_var
func is_breeder_map(account: felt) -> (is_breeder: felt):
end

@storage_var
func is_animal_dead(token_id: felt) -> (is_dead: felt):
end


#
# Constructor
#

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        name : felt, symbol : felt,to_ : felt):
    ERC721_initializer(name, symbol)
    let to = to_
    let token_id : Uint256 = Uint256(1, 0)
    return ()
end

#
# Getters
#

@view
func name{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (name : felt):
    let (name) = ERC721_name()
    return (name)
end

@view
func symbol{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (symbol : felt):
    let (symbol) = ERC721_symbol()
    return (symbol)
end

@view
func balanceOf{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(owner : felt) -> (
        balance : Uint256):
    let (balance : Uint256) = ERC721_balanceOf(owner)
    return (balance)
end

@view
func ownerOf{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256) -> (owner : felt):
    let (owner : felt) = ERC721_ownerOf(token_id)
    return (owner)
end

@view
func getApproved{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256) -> (approved : felt):
    let (approved : felt) = ERC721_getApproved(token_id)
    return (approved)
end

@view
func isApprovedForAll{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        owner : felt, operator : felt) -> (is_approved : felt):
    let (is_approved : felt) = ERC721_isApprovedForAll(owner, operator)
    return (is_approved)
end

@view
func is_breeder{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        account: felt) -> (is_approved: felt):
    let (is_breeder) = is_breeder_map.read(account)
    return (is_approved=is_breeder)
end

@view
func registration_price{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        ) -> (price: Uint256):
    return (price=Uint256(REGISTRATION_PRICE, 0))
end

# Ability to record animal characteristics in contract Need to add ERC721_mint to the constructor and need to add sex,legs, wings for ex1-2.

# @view
#func get_animal_characteristics{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
#    token_id : Uint256 ) -> (sex : felt, legs : felt, wings : felt):
#let (sex : felt) = ERC721_sex()
#let (legs : felt) = ERC721_legs()
#let (wings : felt) = ERC721_wings()
#return(sex, legs, wings)
#end

# Uses struct for anmial characterists.

@view
func get_animal_characteristics{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        token_id:  Uint256) -> (sex:  felt, legs:  felt, wings:  felt):
    # Ensures token_id is valid
    let (exists) = _exists(token_id)
    assert exists = 1
    # Get the animal
    let (animal) = animals.read(token_id=token_id.low)
    return (animal.sex, animal.legs, animal.wings)
end

#
# Externals
#


@external
func register_me_as_breeder{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
        ) -> (is_added:  felt):
    # Check that the caller is not zero
    let (caller_address) = get_caller_address()
    assert_not_zero(caller_address)
    # Register as breeder
    is_breeder_map.write(account=caller_address, value=1)
    return (is_added=1)
end

@external
func declare_animal{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
        sex: felt, legs: felt, wings: felt) -> (token_id: Uint256):
    # Check that the caller is not zero
    let (caller_address) = get_caller_address()
    assert_not_zero(caller_address)

    let (token_id) = next_token_id.read()
    
    # Store the animal properties
    animals.write(
        token_id=token_id, 
        value=Animal(sex=sex, legs=legs, wings=wings)
    )

    # Mint the token
    ERC721_mint(caller_address, Uint256(token_id, 0))

    # Update the next token id
    let (token_id) = next_token_id.read()
    next_token_id.write(token_id + 1)

    return (Uint256(token_id, 0))
end

@external
func declare_dead_animal{pedersen_ptr: HashBuiltin*, syscall_ptr: felt*, range_check_ptr}(
        token_id:  Uint256):
    # Ensures token_id is valid
    let (exists) = _exists(token_id)
    assert exists = 1
    # Set the animal dead
    is_animal_dead.write(token_id=(token_id.low), value=1)
    return ()
end



@external
func approve{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
        to : felt, token_id : Uint256):
    ERC721_approve(to, token_id)
    return ()
end

@external
func setApprovalForAll{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        operator : felt, approved : felt):
    ERC721_setApprovalForAll(operator, approved)
    return ()
end

@external
func transferFrom{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
        _from : felt, to : felt, token_id : Uint256):
    ERC721_transferFrom(_from, to, token_id)
    return ()
end

@external
func safeTransferFrom{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
        _from : felt, to : felt, token_id : Uint256, data_len : felt, data : felt*):
    ERC721_safeTransferFrom(_from, to, token_id, data_len, data)
    return ()
end
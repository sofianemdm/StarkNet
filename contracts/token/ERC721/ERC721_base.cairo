%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.math import assert_not_zero, assert_not_equal
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.uint256 import (
    Uint256, uint256_add, uint256_sub
)

from contracts.token.ERC721.ERC165_base import (
    ERC165_register_interface
)

from contracts.token.ERC721.IERC721_Receiver import IERC721_Receiver

#
# Storage
#


#@storage_var
#func ERC721_is_animal_dead(token_id: felt) -> (is_dead: felt):
#end

@storage_var
func ERC721_name_() -> (name: felt):
end

@storage_var
func ERC721_symbol_() -> (symbol: felt):
end

@storage_var
func ERC721_age_() -> (age :felt):
end


@storage_var
func ERC721_owners(token_id: Uint256) -> (owner: felt):
end

@storage_var
func ERC721_balances(account: felt) -> (balance: Uint256):
end

# May need to 
#@storage_var
#func is_added() -> (i)

@storage_var
func ERC721_token_approvals(token_id: Uint256) -> (res: felt):
end

@storage_var
func ERC721_operator_approvals(owner: felt, operator: felt) -> (res: felt):
end

#
# Events
#

@event
func Transfer(_from: felt, to: felt, tokenId: Uint256):
end

@event
func Approve(owner: felt, approved: felt, tokenId: Uint256):
end

@event
func ApprovalForAll(owner: felt, operator: felt, approved: felt):
end


#
# Constructor
#

func ERC721_initializer{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        name: felt,
        symbol: felt
        #sex: felt,
        #legs: felt,
        #wings: felt,
    ):
    ERC721_name_.write(name)
    ERC721_symbol_.write(symbol)
   # ERC721_sex_.write(sex)
   # ERC721_legs_.write(legs)
   # ERC721_wings_.write(wings)
    # register IERC721
    ERC165_register_interface(0x80ac58cd)
    return ()
end

#
# Getters
#

func ERC721_age{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (age: felt):
    let (age) = ERC721_age_.read()
    return (age)
end


#func ERC721_dead{ syscall_ptr : felt*,
#        pedersen_ptr : HashBuiltin*,
#        range_check_ptr
#    }() -> (dead: felt):
#    let (dead) = ERC721_is_animal_dead_.read(token_id)
#    return (dead)
#end

func ERC721_name{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (name: felt):
    let (name) = ERC721_name_.read()
    return (name)
end

func ERC721_symbol{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (symbol: felt):
    let (symbol) = ERC721_symbol_.read()
    return (symbol)
end

func ERC721_balanceOf{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(owner: felt) -> (balance: Uint256):
    let (balance: Uint256) = ERC721_balances.read(owner)
    assert_not_zero(owner)
    return (balance)
end

func ERC721_ownerOf{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(token_id: Uint256) -> (owner: felt):
    let (owner) = ERC721_owners.read(token_id)
    # Ensuring the query is not for nonexistent token
    assert_not_zero(owner)
    return (owner)
end

func ERC721_getApproved{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(token_id: Uint256) -> (approved: felt):
    let (exists) = _exists(token_id)
    assert exists = 1

    let (approved) = ERC721_token_approvals.read(token_id)
    return (approved)
end

func ERC721_isApprovedForAll{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(owner: felt, operator: felt) -> (is_approved: felt):
    let (is_approved) = ERC721_operator_approvals.read(owner=owner, operator=operator)
    return (is_approved)
end

#
# Externals
#

# Original idea to create and declare animals. 

#func ERC721_declare_animal{
#        pedersen_ptr: HashBuiltin*,
#       syscall_ptr: felt*,
#        range_check_ptr
#    }()->(sex: felt, legs: felt, wings: felt):
#    # Checks caller is not zero address
#    let (caller) = get_caller_address()
#    assert_not_zero(caller)
#    let (sex) = ERC721_sex_input_.read()
#    let (legs) = ERC721_legs_input_.read()
#    let (wings) = ERC721_wings_input_.read()
#    #set owner as the person calling the function and approve
#    let (owner) = get_caller_address()
#    _approve(owner, to, token_id)
#    return (sex, legs, wings)
#    end


func ERC721_approve{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    }(to: felt, token_id: Uint256):
    # Checks caller is not zero address
    let (caller) = get_caller_address()
    assert_not_zero(caller)

    # Ensures 'owner' does not equal 'to'
    let (owner) = ERC721_owners.read(token_id)
    assert_not_equal(owner, to)

    # Checks that either caller equals owner or
    # caller isApprovedForAll on behalf of owner
    if caller == owner:
        _approve(owner, to, token_id)
        return ()
    else:
        let (is_approved) = ERC721_operator_approvals.read(owner, caller)
        assert_not_zero(is_approved)
        _approve(owner, to, token_id)
        return ()
    end
end

func ERC721_setApprovalForAll{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(operator: felt, approved: felt):
    # Ensures caller is neither zero address nor operator
    let (caller) = get_caller_address()
    assert_not_zero(caller)
    assert_not_equal(caller, operator)

    # Make sure `approved` is a boolean (0 or 1)
    assert approved * (1 - approved) = 0

    ERC721_operator_approvals.write(owner=caller, operator=operator, value=approved)

    # Emit ApprovalForAll event
    ApprovalForAll.emit(owner=caller, operator=operator, approved=approved)
    return ()
end

func ERC721_transferFrom{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    }(_from: felt, to: felt, token_id: Uint256):
    alloc_locals

    let (caller) = get_caller_address()
    let (is_approved) = _is_approved_or_owner(caller, token_id)
    assert_not_zero(caller * is_approved)
    # Note that if either `is_approved` or `caller` equals `0`,
    # then this method should fail.
    # The `caller` address and `is_approved` boolean are both field elements
    # meaning that a*0==0 for all a in the field,
    # therefore a*b==0 implies that at least one of a,b is zero in the field

    _transfer(_from, to, token_id)
    return ()
end

func ERC721_safeTransferFrom{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    }(
        _from: felt,
        to: felt,
        token_id: Uint256,
        data_len: felt,
        data: felt*
    ):
    alloc_locals

    let (caller) = get_caller_address()
    let (is_approved) = _is_approved_or_owner(caller, token_id)
    assert_not_zero(caller * is_approved)
    # Note that if either `is_approved` or `caller` equals `0`,
    # then this method should fail.
    # The `caller` address and `is_approved` boolean are both field elements
    # meaning that a*0==0 for all a in the field,

    _safe_transfer(_from, to, token_id, data_len, data)
    return ()
end

func ERC721_mint{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    }(to: felt, token_id: Uint256):
    assert_not_zero(to)

    # Ensures token_id is unique
    let (exists) = _exists(token_id)
    assert exists = 0

    let (balance: Uint256) = ERC721_balances.read(to)
    # Overflow is not possible because token_ids are checked for duplicate ids with `_exists()`
    # thus, each token is guaranteed to be a unique uint256
    let (new_balance: Uint256, _) = uint256_add(balance, Uint256(1, 0))
    ERC721_balances.write(to, new_balance)

    # low + high felts = uint256
    ERC721_owners.write(token_id, to)

    # Emit Transfer event
    Transfer.emit(_from=0, to=to, tokenId=token_id)
    return ()
end

func ERC721_burn{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    }(token_id: Uint256):
    alloc_locals
    let (local owner) = ERC721_ownerOf(token_id)

    # Clear approvals
    _approve(owner, 0, token_id)

    # Decrease owner balance
    let (balance: Uint256) = ERC721_balances.read(owner)
    let (new_balance) = uint256_sub(balance, Uint256(1, 0))
    ERC721_balances.write(owner, new_balance)

    # Delete owner
    ERC721_owners.write(token_id, 0)

    # Emit Transfer event
    Transfer.emit(_from=owner, to=0, tokenId=token_id)
    return ()
end

func ERC721_safeMint{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    }(
        to: felt,
        token_id: Uint256,
        data_len: felt,
        data: felt*
    ):
    ERC721_mint(to, token_id)
    _check_onERC721Received(
        0,
        to,
        token_id,
        data_len,
        data
    )
    return ()
end

#
# Internals
#

func _approve{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(owner: felt, to: felt, token_id: Uint256):
    ERC721_token_approvals.write(token_id, to)
    Approve.emit(owner=owner, approved=to, tokenId=token_id)
    return ()
end

func _is_approved_or_owner{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    }(spender: felt, token_id: Uint256) -> (res: felt):
    alloc_locals

    let (exists) = _exists(token_id)
    assert exists = 1

    let (owner) = ERC721_ownerOf(token_id)
    if owner == spender:
        return (1)
    end

    let (approved_addr) = ERC721_getApproved(token_id)
    if approved_addr == spender:
        return (1)
    end

    let (is_operator) = ERC721_isApprovedForAll(owner, spender)
    if is_operator == 1:
        return (1)
    end

    return (0)
end

func _exists{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(token_id: Uint256) -> (res: felt):
    let (res) = ERC721_owners.read(token_id)

    if res == 0:
        return (0)
    else:
        return (1)
    end
end

func _transfer{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_from: felt, to: felt, token_id: Uint256):
    # ownerOf ensures '_from' is not the zero address
    let (_ownerOf) = ERC721_ownerOf(token_id)
    assert _ownerOf = _from

    assert_not_zero(to)

    # Clear approvals
    _approve(_ownerOf, 0, token_id)

    # Decrease owner balance
    let (owner_bal) = ERC721_balances.read(_from)
    let (new_balance) = uint256_sub(owner_bal, Uint256(1, 0))
    ERC721_balances.write(_from, new_balance)

    # Increase receiver balance
    let (receiver_bal) = ERC721_balances.read(to)
    # overflow not possible because token_id must be unique
    let (new_balance: Uint256, _) = uint256_add(receiver_bal, Uint256(1, 0))
    ERC721_balances.write(to, new_balance)

    # Update token_id owner
    ERC721_owners.write(token_id, to)

    # Emit transfer event
    Transfer.emit(_from=_from, to=to, tokenId=token_id)
    return ()
end

func _safe_transfer{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        _from: felt,
        to: felt,
        token_id: Uint256,
        data_len: felt,
        data: felt*
    ):
    _transfer(_from, to, token_id)

    let (success) = _check_onERC721Received(_from, to, token_id, data_len, data)
    assert_not_zero(success)
    return ()
end

func _check_onERC721Received{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        _from: felt,
        to: felt,
        token_id: Uint256,
        data_len: felt,
        data: felt*
    ) -> (success: felt):
    # We need to consider how to differentiate between EOA and contracts
    # and insert a conditional to know when to use the proceeding check
    let (caller) = get_caller_address()
    # The first parameter in an imported interface is the contract
    # address of the interface being called
    let (selector) = IERC721_Receiver.onERC721Received(
        to,
        caller,
        _from,
        token_id,
        data_len,
        data
    )

    # ERC721_RECEIVER_ID
    assert (selector) = 0x150b7a02

    # Cairo equivalent to 'return (true)'
    return (1)
end

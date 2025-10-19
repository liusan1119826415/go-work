// Code generated - DO NOT EDIT.
// This file is a generated binding and any manual changes will be lost.

package count

import (
	"errors"
	"math/big"
	"strings"

	ethereum "github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/event"
)

// Reference imports to suppress errors if they are not otherwise used.
var (
	_ = errors.New
	_ = big.NewInt
	_ = strings.NewReader
	_ = ethereum.NotFound
	_ = bind.Bind
	_ = common.Big1
	_ = types.BloomLookup
	_ = event.NewSubscription
	_ = abi.ConvertType
)

// CountMetaData contains all meta data concerning the Count contract.
var CountMetaData = &bind.MetaData{
	ABI: "[{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"_initialCount\",\"type\":\"uint256\"}],\"stateMutability\":\"nonpayable\",\"type\":\"constructor\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":false,\"internalType\":\"uint256\",\"name\":\"newCount\",\"type\":\"uint256\"},{\"indexed\":true,\"internalType\":\"address\",\"name\":\"by\",\"type\":\"address\"},{\"indexed\":false,\"internalType\":\"uint256\",\"name\":\"timestamp\",\"type\":\"uint256\"}],\"name\":\"CountDecremented\",\"type\":\"event\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":false,\"internalType\":\"uint256\",\"name\":\"newCount\",\"type\":\"uint256\"},{\"indexed\":true,\"internalType\":\"address\",\"name\":\"by\",\"type\":\"address\"},{\"indexed\":false,\"internalType\":\"uint256\",\"name\":\"timestamp\",\"type\":\"uint256\"}],\"name\":\"CountIncremented\",\"type\":\"event\"},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"_value\",\"type\":\"uint256\"}],\"name\":\"decrement\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"_value\",\"type\":\"uint256\"}],\"name\":\"increment\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"owner\",\"outputs\":[{\"internalType\":\"address\",\"name\":\"\",\"type\":\"address\"}],\"stateMutability\":\"view\",\"type\":\"function\"}]",
	Bin: "0x6080604052348015600e575f5ffd5b506040516104e73803806104e78339818101604052810190602e919060ab565b805f819055503360015f6101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff1602179055505060d1565b5f5ffd5b5f819050919050565b608d81607d565b81146096575f5ffd5b50565b5f8151905060a5816086565b92915050565b5f6020828403121560bd5760bc6079565b5b5f60c8848285016099565b91505092915050565b610409806100de5f395ff3fe608060405234801561000f575f5ffd5b506004361061003f575f3560e01c80633a9ebefd146100435780637cf5dab01461005f5780638da5cb5b1461007b575b5f5ffd5b61005d6004803603810190610058919061020f565b610099565b005b6100796004803603810190610074919061020f565b610148565b005b6100836101b3565b6040516100909190610279565b60405180910390f35b805f5410156100dd576040517f08c379a00000000000000000000000000000000000000000000000000000000081526004016100d4906102ec565b60405180910390fd5b805f5f8282546100ed9190610337565b925050819055503373ffffffffffffffffffffffffffffffffffffffff167f444e38f411c153358b886c641b394b3f7f1f09be3a7359621c5453340a241cba5f544260405161013d929190610379565b60405180910390a250565b805f5f82825461015891906103a0565b925050819055503373ffffffffffffffffffffffffffffffffffffffff167fb6aa5bfdc1ab753194658fada8fa1725a667cdea7df54bd400f8bced617dfd4c5f54426040516101a8929190610379565b60405180910390a250565b60015f9054906101000a900473ffffffffffffffffffffffffffffffffffffffff1681565b5f5ffd5b5f819050919050565b6101ee816101dc565b81146101f8575f5ffd5b50565b5f81359050610209816101e5565b92915050565b5f60208284031215610224576102236101d8565b5b5f610231848285016101fb565b91505092915050565b5f73ffffffffffffffffffffffffffffffffffffffff82169050919050565b5f6102638261023a565b9050919050565b61027381610259565b82525050565b5f60208201905061028c5f83018461026a565b92915050565b5f82825260208201905092915050565b7f636f756e742063616e6e6f74206265206c657373207468616e207a65726f00005f82015250565b5f6102d6601e83610292565b91506102e1826102a2565b602082019050919050565b5f6020820190508181035f830152610303816102ca565b9050919050565b7f4e487b71000000000000000000000000000000000000000000000000000000005f52601160045260245ffd5b5f610341826101dc565b915061034c836101dc565b92508282039050818111156103645761036361030a565b5b92915050565b610373816101dc565b82525050565b5f60408201905061038c5f83018561036a565b610399602083018461036a565b9392505050565b5f6103aa826101dc565b91506103b5836101dc565b92508282019050808211156103cd576103cc61030a565b5b9291505056fea2646970667358221220b62eb197ef2da9024902d5565f2e0cd97e04b6d31c5be7ce77e9474144c0aa2d64736f6c634300081e0033",
}

// CountABI is the input ABI used to generate the binding from.
// Deprecated: Use CountMetaData.ABI instead.
var CountABI = CountMetaData.ABI

// CountBin is the compiled bytecode used for deploying new contracts.
// Deprecated: Use CountMetaData.Bin instead.
var CountBin = CountMetaData.Bin

// DeployCount deploys a new Ethereum contract, binding an instance of Count to it.
func DeployCount(auth *bind.TransactOpts, backend bind.ContractBackend, _initialCount *big.Int) (common.Address, *types.Transaction, *Count, error) {
	parsed, err := CountMetaData.GetAbi()
	if err != nil {
		return common.Address{}, nil, nil, err
	}
	if parsed == nil {
		return common.Address{}, nil, nil, errors.New("GetABI returned nil")
	}

	address, tx, contract, err := bind.DeployContract(auth, *parsed, common.FromHex(CountBin), backend, _initialCount)
	if err != nil {
		return common.Address{}, nil, nil, err
	}
	return address, tx, &Count{CountCaller: CountCaller{contract: contract}, CountTransactor: CountTransactor{contract: contract}, CountFilterer: CountFilterer{contract: contract}}, nil
}

// Count is an auto generated Go binding around an Ethereum contract.
type Count struct {
	CountCaller     // Read-only binding to the contract
	CountTransactor // Write-only binding to the contract
	CountFilterer   // Log filterer for contract events
}

// CountCaller is an auto generated read-only Go binding around an Ethereum contract.
type CountCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// CountTransactor is an auto generated write-only Go binding around an Ethereum contract.
type CountTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// CountFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type CountFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// CountSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type CountSession struct {
	Contract     *Count            // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// CountCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type CountCallerSession struct {
	Contract *CountCaller  // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts // Call options to use throughout this session
}

// CountTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type CountTransactorSession struct {
	Contract     *CountTransactor  // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// CountRaw is an auto generated low-level Go binding around an Ethereum contract.
type CountRaw struct {
	Contract *Count // Generic contract binding to access the raw methods on
}

// CountCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type CountCallerRaw struct {
	Contract *CountCaller // Generic read-only contract binding to access the raw methods on
}

// CountTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type CountTransactorRaw struct {
	Contract *CountTransactor // Generic write-only contract binding to access the raw methods on
}

// NewCount creates a new instance of Count, bound to a specific deployed contract.
func NewCount(address common.Address, backend bind.ContractBackend) (*Count, error) {
	contract, err := bindCount(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &Count{CountCaller: CountCaller{contract: contract}, CountTransactor: CountTransactor{contract: contract}, CountFilterer: CountFilterer{contract: contract}}, nil
}

// NewCountCaller creates a new read-only instance of Count, bound to a specific deployed contract.
func NewCountCaller(address common.Address, caller bind.ContractCaller) (*CountCaller, error) {
	contract, err := bindCount(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &CountCaller{contract: contract}, nil
}

// NewCountTransactor creates a new write-only instance of Count, bound to a specific deployed contract.
func NewCountTransactor(address common.Address, transactor bind.ContractTransactor) (*CountTransactor, error) {
	contract, err := bindCount(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &CountTransactor{contract: contract}, nil
}

// NewCountFilterer creates a new log filterer instance of Count, bound to a specific deployed contract.
func NewCountFilterer(address common.Address, filterer bind.ContractFilterer) (*CountFilterer, error) {
	contract, err := bindCount(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &CountFilterer{contract: contract}, nil
}

// bindCount binds a generic wrapper to an already deployed contract.
func bindCount(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := CountMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_Count *CountRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _Count.Contract.CountCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_Count *CountRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _Count.Contract.CountTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_Count *CountRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _Count.Contract.CountTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_Count *CountCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _Count.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_Count *CountTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _Count.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_Count *CountTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _Count.Contract.contract.Transact(opts, method, params...)
}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_Count *CountCaller) Owner(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _Count.contract.Call(opts, &out, "owner")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_Count *CountSession) Owner() (common.Address, error) {
	return _Count.Contract.Owner(&_Count.CallOpts)
}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_Count *CountCallerSession) Owner() (common.Address, error) {
	return _Count.Contract.Owner(&_Count.CallOpts)
}

// Decrement is a paid mutator transaction binding the contract method 0x3a9ebefd.
//
// Solidity: function decrement(uint256 _value) returns()
func (_Count *CountTransactor) Decrement(opts *bind.TransactOpts, _value *big.Int) (*types.Transaction, error) {
	return _Count.contract.Transact(opts, "decrement", _value)
}

// Decrement is a paid mutator transaction binding the contract method 0x3a9ebefd.
//
// Solidity: function decrement(uint256 _value) returns()
func (_Count *CountSession) Decrement(_value *big.Int) (*types.Transaction, error) {
	return _Count.Contract.Decrement(&_Count.TransactOpts, _value)
}

// Decrement is a paid mutator transaction binding the contract method 0x3a9ebefd.
//
// Solidity: function decrement(uint256 _value) returns()
func (_Count *CountTransactorSession) Decrement(_value *big.Int) (*types.Transaction, error) {
	return _Count.Contract.Decrement(&_Count.TransactOpts, _value)
}

// Increment is a paid mutator transaction binding the contract method 0x7cf5dab0.
//
// Solidity: function increment(uint256 _value) returns()
func (_Count *CountTransactor) Increment(opts *bind.TransactOpts, _value *big.Int) (*types.Transaction, error) {
	return _Count.contract.Transact(opts, "increment", _value)
}

// Increment is a paid mutator transaction binding the contract method 0x7cf5dab0.
//
// Solidity: function increment(uint256 _value) returns()
func (_Count *CountSession) Increment(_value *big.Int) (*types.Transaction, error) {
	return _Count.Contract.Increment(&_Count.TransactOpts, _value)
}

// Increment is a paid mutator transaction binding the contract method 0x7cf5dab0.
//
// Solidity: function increment(uint256 _value) returns()
func (_Count *CountTransactorSession) Increment(_value *big.Int) (*types.Transaction, error) {
	return _Count.Contract.Increment(&_Count.TransactOpts, _value)
}

// CountCountDecrementedIterator is returned from FilterCountDecremented and is used to iterate over the raw logs and unpacked data for CountDecremented events raised by the Count contract.
type CountCountDecrementedIterator struct {
	Event *CountCountDecremented // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *CountCountDecrementedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(CountCountDecremented)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(CountCountDecremented)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *CountCountDecrementedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *CountCountDecrementedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// CountCountDecremented represents a CountDecremented event raised by the Count contract.
type CountCountDecremented struct {
	NewCount  *big.Int
	By        common.Address
	Timestamp *big.Int
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterCountDecremented is a free log retrieval operation binding the contract event 0x444e38f411c153358b886c641b394b3f7f1f09be3a7359621c5453340a241cba.
//
// Solidity: event CountDecremented(uint256 newCount, address indexed by, uint256 timestamp)
func (_Count *CountFilterer) FilterCountDecremented(opts *bind.FilterOpts, by []common.Address) (*CountCountDecrementedIterator, error) {

	var byRule []interface{}
	for _, byItem := range by {
		byRule = append(byRule, byItem)
	}

	logs, sub, err := _Count.contract.FilterLogs(opts, "CountDecremented", byRule)
	if err != nil {
		return nil, err
	}
	return &CountCountDecrementedIterator{contract: _Count.contract, event: "CountDecremented", logs: logs, sub: sub}, nil
}

// WatchCountDecremented is a free log subscription operation binding the contract event 0x444e38f411c153358b886c641b394b3f7f1f09be3a7359621c5453340a241cba.
//
// Solidity: event CountDecremented(uint256 newCount, address indexed by, uint256 timestamp)
func (_Count *CountFilterer) WatchCountDecremented(opts *bind.WatchOpts, sink chan<- *CountCountDecremented, by []common.Address) (event.Subscription, error) {

	var byRule []interface{}
	for _, byItem := range by {
		byRule = append(byRule, byItem)
	}

	logs, sub, err := _Count.contract.WatchLogs(opts, "CountDecremented", byRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(CountCountDecremented)
				if err := _Count.contract.UnpackLog(event, "CountDecremented", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseCountDecremented is a log parse operation binding the contract event 0x444e38f411c153358b886c641b394b3f7f1f09be3a7359621c5453340a241cba.
//
// Solidity: event CountDecremented(uint256 newCount, address indexed by, uint256 timestamp)
func (_Count *CountFilterer) ParseCountDecremented(log types.Log) (*CountCountDecremented, error) {
	event := new(CountCountDecremented)
	if err := _Count.contract.UnpackLog(event, "CountDecremented", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

// CountCountIncrementedIterator is returned from FilterCountIncremented and is used to iterate over the raw logs and unpacked data for CountIncremented events raised by the Count contract.
type CountCountIncrementedIterator struct {
	Event *CountCountIncremented // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *CountCountIncrementedIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(CountCountIncremented)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(CountCountIncremented)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *CountCountIncrementedIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *CountCountIncrementedIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// CountCountIncremented represents a CountIncremented event raised by the Count contract.
type CountCountIncremented struct {
	NewCount  *big.Int
	By        common.Address
	Timestamp *big.Int
	Raw       types.Log // Blockchain specific contextual infos
}

// FilterCountIncremented is a free log retrieval operation binding the contract event 0xb6aa5bfdc1ab753194658fada8fa1725a667cdea7df54bd400f8bced617dfd4c.
//
// Solidity: event CountIncremented(uint256 newCount, address indexed by, uint256 timestamp)
func (_Count *CountFilterer) FilterCountIncremented(opts *bind.FilterOpts, by []common.Address) (*CountCountIncrementedIterator, error) {

	var byRule []interface{}
	for _, byItem := range by {
		byRule = append(byRule, byItem)
	}

	logs, sub, err := _Count.contract.FilterLogs(opts, "CountIncremented", byRule)
	if err != nil {
		return nil, err
	}
	return &CountCountIncrementedIterator{contract: _Count.contract, event: "CountIncremented", logs: logs, sub: sub}, nil
}

// WatchCountIncremented is a free log subscription operation binding the contract event 0xb6aa5bfdc1ab753194658fada8fa1725a667cdea7df54bd400f8bced617dfd4c.
//
// Solidity: event CountIncremented(uint256 newCount, address indexed by, uint256 timestamp)
func (_Count *CountFilterer) WatchCountIncremented(opts *bind.WatchOpts, sink chan<- *CountCountIncremented, by []common.Address) (event.Subscription, error) {

	var byRule []interface{}
	for _, byItem := range by {
		byRule = append(byRule, byItem)
	}

	logs, sub, err := _Count.contract.WatchLogs(opts, "CountIncremented", byRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(CountCountIncremented)
				if err := _Count.contract.UnpackLog(event, "CountIncremented", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseCountIncremented is a log parse operation binding the contract event 0xb6aa5bfdc1ab753194658fada8fa1725a667cdea7df54bd400f8bced617dfd4c.
//
// Solidity: event CountIncremented(uint256 newCount, address indexed by, uint256 timestamp)
func (_Count *CountFilterer) ParseCountIncremented(log types.Log) (*CountCountIncremented, error) {
	event := new(CountCountIncremented)
	if err := _Count.contract.UnpackLog(event, "CountIncremented", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}

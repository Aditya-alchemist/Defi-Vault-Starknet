//deployed at 0x02eafc50093e25fc8d3e14c45b8d4a6d8d21ba647db162cf335c78609b74d479

#[starknet::interface]
trait IERC<T>{
    fn deposit(ref self: T,amount:u256);
    fn withdraw(ref self: T,shares:u256);
    fn minting(ref self: T,amount:u256);
    fn burning(ref self: T,amount:u256);
    fn shares(self: @T,recipient: starknet::ContractAddress) -> u256;
}


#[starknet::contract]
mod vault{
    use starknet::event::EventEmitter;
use starknet::ContractAddress;
    use starknet::{get_caller_address,get_contract_address};
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess,Map,StorageMapReadAccess,StorageMapWriteAccess};
    use openzeppelin::token::erc20::{ERC20Component, ERC20HooksEmptyImpl};

    component!(path: ERC20Component, storage: erc20, event: ERC20Event);

    #[abi(embed_v0)]
    impl ERC20MixinImpl = ERC20Component::ERC20Impl<ContractState>;

    impl ERC20InternalImpl = ERC20Component::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc20: ERC20Component::Storage,
        balanceofshares: Map<ContractAddress,u256>,
        minted: Map<ContractAddress,bool>,
        owner: ContractAddress,

    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC20Event: ERC20Component::Event,
        MintEvent: MintEvent,
        DepositEvent: DepositEvent,
        WithdrawEvent: WithdrawEvent,
        BurningEvent: BurningEvent,
    }

    #[derive(Drop, starknet::Event)]
    struct MintEvent {
        recipient: ContractAddress,
        amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct DepositEvent {
        recipient: ContractAddress,
        amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct BurningEvent {
        recipient: ContractAddress,
        amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct WithdrawEvent {
        recipient: ContractAddress,
        shares: u256,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        fixed_supply: u256,
    ) {
        let name = "Defi Vault";
        let symbol = "DVLT";
        self.erc20.initializer(name, symbol);
        let recipient = get_caller_address();
        self.erc20.mint(recipient, fixed_supply);
        self.owner.write(recipient);
    }

    #[abi(embed_v0)]
    impl t of super::IERC<ContractState>{
         fn minting(ref self:ContractState,amount:u256){
            let recipient = get_caller_address();
           let mini= self.minted.read(recipient);
           assert(mini == false,'Already minted');
           assert(amount > 0, 'Amount must be greater than 0');
           assert(amount <= 10,'Amount less than or equal to 10');
          
            
                self.erc20.mint(recipient, amount);
                self.emit(Event::MintEvent(MintEvent{
                    recipient,
                    amount,
                }));
                self.minted.write(recipient,true);
          }
    
          fn deposit(ref self:ContractState,amount:u256){
                assert(amount > 0, 'Amount must be greater than 0');
                let caller = get_caller_address();
                let shares = amount; 
                let balanceshare= self.balanceofshares.read(caller);
                let newbalance = balanceshare + shares;
                self.balanceofshares.write(caller,newbalance);
                self.erc20.transfer_from(caller,get_contract_address(),amount);
                self.emit(Event::DepositEvent(DepositEvent{
                    recipient: caller,
                    amount,
                }));

          }    







          
        

        fn withdraw(ref self: ContractState, shares: u256) {
    let caller = get_caller_address();
    let contract_address = get_contract_address();
    assert(shares > 0, 'Shares must be greater than 0');

    let user_shares = self.balanceofshares.read(caller);
    assert(user_shares >= shares, 'Not enough shares');

    let vault_balance = self.erc20.balance_of(contract_address);
    assert(vault_balance >= shares, 'Vault has insufficient DVLT');

    self.balanceofshares.write(caller, user_shares - shares);
    self.erc20.transfer(caller, shares);
    self.emit(Event::WithdrawEvent(WithdrawEvent {
        recipient: caller,
        shares,
    }));
}

fn burning(ref self: ContractState,  amount: u256) {
    let caller = get_caller_address();
    assert(amount > 0, 'Amount must be greater than 0');
    assert(caller == self.owner.read(),'Only owner can burn');
    self.erc20.burn(get_contract_address(), amount);
    self.emit(Event::BurningEvent(BurningEvent {
        recipient: caller,
        amount,
    }));

}

fn shares(self: @ContractState, recipient: ContractAddress) -> u256 {
    let balanceshare = self.balanceofshares.read(recipient);
     balanceshare


}    
        
}
}
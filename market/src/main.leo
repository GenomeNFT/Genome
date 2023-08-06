program genomenftmarketplace.aleo {
    struct NftInfo {     

        // The token owner.
        nft_owner: address,

        // Token price
        price: u64,

        // Allow NFT sale
        is_traiding: bool
    }

    record NftRecord{
        // The token owner.
        owner: address,

        // The token image Id.
        image_id: u64
    }

    // Image id => NftInfo
    mapping nfts: u64=> NftInfo;

    // Temporary. Substitute for real money transfer
    mapping balances: address => u64;

    // Mint new NFT.
    // - `imageId` : Id of the image on website.
    // - `price` : Price of the image.
    // - `is_traiding` : Allow NFT sale.
    // Return record with the nft information.
    transition mint(imageId: u64,  price: u64, is_traiding: bool) -> NftRecord {
       
        let new: NftRecord = NftRecord {
            owner: self.caller,
            image_id: imageId
        };

        let info: NftInfo = NftInfo{
            nft_owner: self.caller,
            price: price,
            is_traiding: is_traiding
        };

        return new then finalize(imageId, info);
    }

   
    finalize mint (imageId: u64, info: NftInfo) {
        let savedInfo: NftInfo = Mapping::get_or_use(nfts, imageId, info);

        // check hacker rewrite nft owner if the nft already exists
        assert_eq(info.nft_owner, savedInfo.nft_owner);
    }

    // Buy the NFT.
    // - `imageId` : Id of the image on website.
    // - `amount` : The amount of tokens to buy the NFT.  
    transition buy(imageId: u64, amount: u64) -> NftRecord {       

        // 5% contract interest for every buy 
        let contract_interest : u64 = (amount/100u64)*5u64;
        let owner_amount : u64 = amount - contract_interest;
      
        let info : NftInfo =   NftInfo{
            nft_owner: self.caller,
            price: 0u64,  
            is_traiding: false
        }; 

        let nft: NftRecord = NftRecord {
            owner: self.caller,
            image_id: imageId
        };      

        return nft then finalize(imageId, info, owner_amount, contract_interest);
    }

    finalize  buy(imageId: u64, info: NftInfo,  owner_amount : u64, contract_interest : u64) {
        let savedInfo: NftInfo = Mapping::get(nfts, imageId);

        // check if can buy
        assert_eq(savedInfo.is_traiding, true);

        // check if price equel to amount
        assert_eq(savedInfo.price, owner_amount+contract_interest);           
    
        // add owner balance
        let owner_balance: u64 = Mapping::get_or_use(balances, savedInfo.nft_owner, 0u64);
        Mapping::set(balances, savedInfo.nft_owner, owner_balance + owner_amount);

        // add contract balance
        let contract_balance: u64 = Mapping::get_or_use(balances, aleo17cxjue56ypgpa82c9c53ck9uswjrfxnpyezpjmqlkvsl4y8q4vgsgj54ax, 0u64);
        Mapping::set(balances, aleo17cxjue56ypgpa82c9c53ck9uswjrfxnpyezpjmqlkvsl4y8q4vgsgj54ax,contract_balance + contract_interest);

        // set new owner
        Mapping::set(nfts, imageId, info);    
    }

    // Change traiding information
    // - `imageId` : Id of the image on website.
    // - `price` : Price of the image.
    // - `is_traiding` : Allow NFT sale.
    transition change_sell_info(imageId: u64, price: u64, is_traiding : bool){
        let info: NftInfo = NftInfo{
            nft_owner: self.caller,
            price: price,
            is_traiding: is_traiding
        };

        return then finalize (imageId, info);
    }

    finalize change_sell_info( imageId: u64, info: NftInfo) {
        let savedInfo: NftInfo = Mapping::get(nfts, imageId);

        // check owner
        assert_eq(savedInfo.nft_owner, info.nft_owner);
        
        Mapping::set(nfts, imageId, info);
    }
}
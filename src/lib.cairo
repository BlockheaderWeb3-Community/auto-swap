pub mod base {
    pub mod types;
    pub mod errors;
}

pub mod interfaces {
    pub mod autoswappr;
    pub mod iavnu_exchange;
}

pub mod mocks {
    pub mod erc20;
}

#[cfg(test)]
pub mod tests {
    pub mod test_autoswapper;
}

mod autoswappr;

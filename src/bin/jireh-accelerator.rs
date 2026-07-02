#![cfg_attr(target_os = "windows", windows_subsystem = "windows")]

use std::env;

use clap::Parser;
use jireh_accelerator::cli::{self, Cli};
#[cfg(target_os = "windows")]
use jireh_accelerator::platform::prepare_windows_cli_stdio;

fn main() -> anyhow::Result<()> {
    let args: Vec<_> = env::args_os().collect();
    #[cfg(target_os = "windows")]
    prepare_windows_cli_stdio(&args);
    let cli = Cli::parse_from(args);
    cli::run(cli)
}

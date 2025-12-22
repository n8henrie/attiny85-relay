#![no_std]
#![no_main]

use panic_halt as _;

use attiny_hal::prelude::*;

type CoreClock = attiny_hal::clock::MHz1;
type Delay = attiny_hal::delay::Delay<CoreClock>;

#[attiny_hal::entry]
fn main() -> ! {
    let dp = attiny_hal::Peripherals::take().unwrap();
    let pins = attiny_hal::pins!(dp);

    let mut led = pins.pb3.into_output();

    loop {
        led.toggle();
        Delay::new().delay_ms(1000_u16)
    }
}

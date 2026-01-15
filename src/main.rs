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

    let mut sensor = pins.pb3.into_output();
    let mut power = pins.pb4.into_output();

    loop {
        power.set_high();
        Delay::new().delay_ms(15_000_u16);
        sensor.set_high();
        Delay::new().delay_ms(8_000_u16);
        sensor.set_low();
        Delay::new().delay_ms(4_000_u16);
        power.set_low();
        Delay::new().delay_ms(2_000_u16);
    }
}

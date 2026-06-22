#![no_std]
#![no_main]

use panic_halt as _;

use attiny_hal::prelude::*;

type CoreClock = attiny_hal::clock::MHz1;
type Delay = attiny_hal::delay::Delay<CoreClock>;

fn delay_secs(secs: u16) {
    const MULTIPLIER: u16 = 1_000_u16;
    let ms = MULTIPLIER * secs;
    Delay::new().delay_ms(ms);
}

#[attiny_hal::entry]
fn main() -> ! {
    let dp = attiny_hal::Peripherals::take().unwrap();
    let pins = attiny_hal::pins!(dp);

    let mut led_reed = pins.pb3.into_output();
    let mut sensor_power = pins.pb4.into_output();

    loop {
        sensor_power.set_high();
        delay_secs(10);

        led_reed.set_high();
        delay_secs(4);

        led_reed.set_low();

        // over an hour -- time for heartbeat
        delay_secs(4_000);

        sensor_power.set_low();
        delay_secs(60);
    }
}

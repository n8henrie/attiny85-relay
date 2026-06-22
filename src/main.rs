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
        led_reed.set_high();
        delay_secs(10);

        led_reed.set_low();
        delay_secs(4);

        led_reed.set_high();

        // based on firmware heartbeat should be every ~70 minutes; let's
        // use 75 to be safe and double this to get 2
        delay_secs(75 * 2 * 60);

        sensor_power.set_low();
        delay_secs(60);
    }
}

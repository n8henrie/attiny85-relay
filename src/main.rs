#![no_std]
#![no_main]

use panic_halt as _;

use attiny_hal::prelude::*;

type CoreClock = attiny_hal::clock::MHz1;
type Delay = attiny_hal::delay::Delay<CoreClock>;

fn delay_secs(secs: u16) {
    const MAX_SECS_PER_DELAY: u16 = u16::MAX / 1_000;
    const MAX_MS_PER_DELAY: u16 = MAX_SECS_PER_DELAY * 1_000;

    let mut delay = Delay::new();
    for _ in 0..(secs / MAX_SECS_PER_DELAY) {
        delay.delay_ms(MAX_MS_PER_DELAY);
    }
    let remainder = secs % MAX_SECS_PER_DELAY;
    if remainder != 0 {
        delay.delay_ms(remainder * 1_000);
    }
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

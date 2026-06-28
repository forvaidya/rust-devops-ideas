use neomath::arithmetic::{add_integers, add_floats};

fn main() {
    println!("=== Testing add_integers ===");

    // Valid inputs
    match add_integers("5", "3") {
        Ok(result) => println!("5 + 3 = {}", result),
        Err(e) => println!("Error: {}", e),
    }

    match add_integers("-10", "15") {
        Ok(result) => println!("-10 + 15 = {}", result),
        Err(e) => println!("Error: {}", e),
    }

    // Invalid inputs
    match add_integers("abc", "5") {
        Ok(result) => println!("abc + 5 = {}", result),
        Err(e) => println!("Error: {}", e),
    }

    println!("\n=== Testing add_floats ===");

    // Valid inputs
    match add_floats("1.5", "2.5") {
        Ok(result) => println!("1.5 + 2.5 = {}", result),
        Err(e) => println!("Error: {}", e),
    }

    match add_floats("-3.7", "2.2") {
        Ok(result) => println!("-3.7 + 2.2 = {}", result),
        Err(e) => println!("Error: {}", e),
    }

    // Invalid inputs
    match add_floats("1.5", "xyz") {
        Ok(result) => println!("1.5 + xyz = {}", result),
        Err(e) => println!("Error: {}", e),
    }
}

/// Add two integers provided as strings.
///
/// # Arguments
/// * `a` - First integer as a string
/// * `b` - Second integer as a string
///
/// # Returns
/// `Ok(i64)` with the sum, or `Err(String)` with error message
///
/// # Example
/// ```
/// use neomath::arithmetic::add_integers;
/// assert!(add_integers("5", "3").is_ok());
/// ```
pub fn add_integers(a: &str, b: &str) -> Result<i64, String> {
    let num_a: i64 = a.parse().map_err(|_| "Invalid integer input".to_string())?;
    let num_b: i64 = b.parse().map_err(|_| "Invalid integer input".to_string())?;
    Ok(num_a + num_b)
}

/// Add two floats provided as strings.
///
/// # Arguments
/// * `a` - First float as a string
/// * `b` - Second float as a string
///
/// # Returns
/// `Ok(f64)` with the sum, or `Err(String)` with error message
///
/// # Example
/// ```
/// use neomath::arithmetic::add_floats;
/// assert!(add_floats("1.5", "2.5").is_ok());
/// ```
pub fn add_floats(a: &str, b: &str) -> Result<f64, String> {
    let num_a: f64 = a.parse().map_err(|_| "Invalid float input".to_string())?;
    let num_b: f64 = b.parse().map_err(|_| "Invalid float input".to_string())?;
    Ok(num_a + num_b)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_add_integers_valid() {
        assert_eq!(add_integers("5", "3").unwrap(), 8);
        assert_eq!(add_integers("0", "0").unwrap(), 0);
        assert_eq!(add_integers("-5", "10").unwrap(), 5);
    }

    #[test]
    fn test_add_integers_invalid() {
        assert!(add_integers("abc", "5").is_err());
        assert!(add_integers("5", "xyz").is_err());
        assert_eq!(add_integers("abc", "5").unwrap_err(), "Invalid integer input");
    }

    #[test]
    fn test_add_floats_valid() {
        assert!((add_floats("1.5", "2.5").unwrap() - 4.0).abs() < 0.0001);
        assert_eq!(add_floats("0.0", "0.0").unwrap(), 0.0);
        assert!((add_floats("-1.5", "2.5").unwrap() - 1.0).abs() < 0.0001);
    }

    #[test]
    fn test_add_floats_invalid() {
        assert!(add_floats("abc", "1.5").is_err());
        assert!(add_floats("1.5", "xyz").is_err());
        assert_eq!(add_floats("abc", "1.5").unwrap_err(), "Invalid float input");
    }
}

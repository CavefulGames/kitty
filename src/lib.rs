// rust_i18n::i18n!("locales");

// #[macro_export]
// macro_rules! localize {
//     ($s:expr) => {
//         {
// 			use rust_i18n::t;
// 			use sys_locale::get_locale;
// 			use language_tags::LanguageTag;

// 			let locale = get_locale().unwrap();
// 			let tag = LanguageTag::parse(&locale).unwrap();
// 			rust_i18n::set_locale(tag.primary_language());
// 			t!($s)
// 		}
//     };
// }

rust_i18n::i18n!("locales");

pub mod commands;
pub mod requirements;
pub mod localization;

pub use commands::*;

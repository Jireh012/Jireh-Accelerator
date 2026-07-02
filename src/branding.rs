use std::io::Cursor;
use std::sync::OnceLock;

use eframe::egui::{Color32, ColorImage, IconData};
use image::{ImageReader, RgbaImage, imageops::FilterType};

const SOURCE_ICON: &[u8] = include_bytes!("../assets/icons/icon-source.png");
const CORNER_RADIUS_RATIO: f32 = 0.22;

fn source_rgba() -> &'static RgbaImage {
    static CACHE: OnceLock<RgbaImage> = OnceLock::new();
    CACHE.get_or_init(|| {
        ImageReader::new(Cursor::new(SOURCE_ICON))
            .with_guessed_format()
            .expect("icon format must be detectable")
            .decode()
            .expect("embedded icon source must decode")
            .to_rgba8()
    })
}

fn rounded_rect_alpha(x: f32, y: f32, width: f32, height: f32, radius: f32) -> f32 {
    let half_w = width * 0.5;
    let half_h = height * 0.5;
    let cx = x + 0.5 - half_w;
    let cy = y + 0.5 - half_h;
    let r = radius.min(half_w).min(half_h);
    let bx = half_w - r;
    let by = half_h - r;
    let qx = cx.abs() - bx;
    let qy = cy.abs() - by;
    let ax = qx.max(0.0);
    let ay = qy.max(0.0);
    let outside = (ax * ax + ay * ay).sqrt();
    let inside = qx.max(qy).min(0.0);
    let distance = outside + inside - r;
    smoothstep(1.0, 0.0, distance)
}

fn smoothstep(edge0: f32, edge1: f32, x: f32) -> f32 {
    if (edge1 - edge0).abs() < f32::EPSILON {
        return if x >= edge1 { 1.0 } else { 0.0 };
    }
    let t = ((x - edge0) / (edge1 - edge0)).clamp(0.0, 1.0);
    t * t * (3.0 - 2.0 * t)
}

fn apply_rounded_corners(image: &mut RgbaImage) {
    let (width, height) = image.dimensions();
    let radius = width.min(height) as f32 * CORNER_RADIUS_RATIO;
    let w = width as f32;
    let h = height as f32;

    for y in 0..height {
        for x in 0..width {
            let alpha = rounded_rect_alpha(x as f32, y as f32, w, h, radius);
            let pixel = image.get_pixel_mut(x, y);
            pixel[3] = ((pixel[3] as f32) * alpha).round() as u8;
        }
    }
}

pub fn logo_image(size: usize) -> ColorImage {
    let size = size.max(1) as u32;
    let mut resized = image::imageops::resize(source_rgba(), size, size, FilterType::Lanczos3);
    apply_rounded_corners(&mut resized);
    let pixels = resized
        .pixels()
        .map(|pixel| Color32::from_rgba_unmultiplied(pixel[0], pixel[1], pixel[2], pixel[3]))
        .collect();

    ColorImage {
        size: [size as usize, size as usize],
        pixels,
    }
}

pub fn icon_data(size: usize) -> IconData {
    let image = logo_image(size);
    let mut rgba = Vec::with_capacity(image.pixels.len() * 4);
    for pixel in image.pixels {
        rgba.extend_from_slice(&pixel.to_array());
    }

    IconData {
        rgba,
        width: image.size[0] as u32,
        height: image.size[1] as u32,
    }
}


pub fn csub1d (input_array: &Vec<f32>,nx: usize,ny: usize,
                                      output_array: &mut Vec<f32>) {
    for iy in 0..ny {
       for ix in 0..nx {
          output_array[iy * nx + ix] = input_array[iy * nx + ix] + (ix + iy) as f32;
       }
    }
}

use std::env;
fn main() {
   let args: Vec<String> = env::args().collect();
   let cols = args[1].parse::<usize>().unwrap();
   let rows = args[2].parse::<usize>().unwrap();;
   let mut in_array = vec![0.0f32; cols * rows];
   let mut out_array = vec![0.0f32; cols * rows];

   csub1d (&mut in_array,cols,rows,&mut out_array);
}

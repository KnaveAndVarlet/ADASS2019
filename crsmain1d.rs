use std::env;

mod crssub1d;

fn main() {
    let mut nrpt = 100;
    let mut rows = 5;
    let mut cols = 4;
    let args: Vec<String> = env::args().collect();
    if args.len() > 1 {
       match args[1].parse::<usize>() {
          Ok(number) => nrpt = number,
          Err(_error) => println!("Repeats invalid, using {}",nrpt),
       };
       if args.len() > 2 {
          match args[2].parse::<usize>() {
             Ok(number) => rows = number,
             Err(_error) => println!("Rows invalid, using {}",rows),
          };
          if args.len() > 3 {
            match args[3].parse::<usize>() {
               Ok(number) => cols = number,
               Err(_error) => println!("Columns invalid, using {}",cols),
             };
          }
       }
    }
    println!("{} {} {}",nrpt,rows,cols);

    assert_ne!(rows, 0, "rows were zero");
    assert_ne!(cols, 0, "cols were zero");

    let mut in_array = vec![0.0f32; cols * rows];
    let mut out_array = vec![0.0f32; cols * rows];
    for iy in 0..rows {
       for ix in 0..cols {
          in_array[iy * cols + ix] = (cols - ix + rows - iy) as f32;
       }
    }

   println! ("Calling");
    for _irpt in 1..=nrpt {
       crssub1d::csub1d (&mut in_array,cols,rows,&mut out_array);
    }
    println! ("Called");

    'check_loop :
    for iy in 0..rows {
       for ix in 0..cols {
          if out_array[iy * cols + ix] != (in_array[iy * cols + ix] + (ix + iy) as f32) {
             println! ("Error {} {} {} {}",ix,iy,out_array[iy * cols + ix],
                                                             in_array[iy * cols + ix]);
             break 'check_loop;
          }
       }
    }

}

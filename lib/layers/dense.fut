import "layer_type"
import "../nn_types"
import "../util"
import "../random_gen"
import "/futlib/linalg"

module dense (R:real) : layer with t = R.t
                              with input_params = (i32, i32)
                              with activations  = (f_pair_1d R.t)
                              with input        = arr2d R.t
                              with weights      = std_weights R.t
                              with output       = arr2d R.t
                              with cache        = (arr2d R.t, arr2d R.t)
                              with error_in     = arr2d R.t
                              with error_out    = arr2d R.t = {

  type t            = R.t
  type input        = arr2d t
  type weights      = std_weights t
  type output       = arr2d t
  type cache        = (arr2d t, arr2d t)
  type error_in     = arr2d t
  type error_out    = arr2d t
  type b_output     = (error_out, weights)

  type input_params = (i32, i32)
  type activations  = f_pair_1d t

  type dense_tp = NN input weights output cache error_in error_out (apply_grad t)

  module lalg   = linalg R
  module util   = utility R
  module random = normal_random_array R

  let empty_cache:cache= ([[]],[[]])
  let empty_error:error_out = [[]]

  ---- Each input is in row
  let forward  (act:[]t -> []t) (training:bool) ((w,b):weights) (input:input) : (cache, output) =
    let res      = lalg.matmul w (transpose input)
    let res_bias = map2 (\xr b -> map (\x -> (R.(x + b))) xr) res b
    let res_act  = map (\x -> act x) res_bias
    let cache  = if training then (input, res_bias) else empty_cache
    in (cache, transpose res_act)

  let backward (act:[]t -> []t) (first_layer:bool) ((w,_):weights)
                                ((input, inp_w_bias):cache)
                                (error:error_in) : b_output =

    let (res_m, res_n)   = (length inp_w_bias, length inp_w_bias[0])
    let deriv            = unflatten res_m res_n (act (flatten inp_w_bias))
    let delta            = util.mult_matrix (transpose error) deriv
    let w_grad           = lalg.matmul delta (input)
    let b_grad           = map (R.sum) delta
    let error' =
      if first_layer
      then
       empty_error
      else
       transpose (lalg.matmul (transpose w) delta)
    in (error', (w_grad, b_grad))

  let update (f:apply_grad t) (w: weights) (wg:weights) : weights =
    f w wg

  let init ((m,n):input_params) (act:activations) (seed:i32) : dense_tp =
    let w = random.gen_random_array_2d_w_scaling (m,n) seed
    let b = map (\_ -> R.(i32 0)) (0..<n)
    in
    (forward act.1,
     backward act.2,
     update,
    (w,b))

}

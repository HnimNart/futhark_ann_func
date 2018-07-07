import "../types"
import "layer_type"
import "../activations"
import "/futlib/linalg"
import "../util"



module max_pooling_2d (R:real) : layer with t = R.t
                                       with input = [][][]R.t
                                       with input_params = (i32,i32)
                                       with weights = ()
                                       with output  = ([][][]R.t)
                                       with error_in = ([][][]R.t)
                                       with error_out = ([][][]R.t)
                                       with gradients = ([][][]R.t,())
                                       with layer = NN ([][][]R.t) () ([][][]R.t) ([][][](i32, i32)) ([][][]R.t) ([][][]R.t) R.t with act = ()  =  {

  type t = R.t
  type input = [][][]t
  type weights = ()
  type output = [][][]t
  type garbage = [][][](i32, i32)
  type error_in = [][][]t
  type error_out = [][][]t
  type gradients = (error_out, weights)
  type input_params = (i32, i32)

  type act = ()
  type layer = NN input weights output garbage error_in error_out t

  let max_val  [m][n] (input:[m][n]t) =
    let inp_flat = flatten input
    let argmax =  reduce (\n i -> if unsafe R.(inp_flat[n] > inp_flat[i]) then n else i) 0 (iota (length inp_flat))
    let (i,j) = (argmax / n, argmax % n )
    in ( (i,j),  inp_flat[argmax])


  let forward ((m,n ):(i32, i32)) (_:weights) (input:input) : (garbage, output) =
    let ixs = map (\x -> x * m) (0..<(length input[0,0]/2)) -- should be divided by stride
    let jxs = map (\x -> x * n) (0..<(length input[0]/2))
    let res = unsafe map (\layer -> map (\i -> map (\j -> let ((i',j'), res) = max_val layer[i:i+m,j:j+n]
                                                   in (((i + i'), (j' + j)), res))  jxs) ixs) input

    let index = map (\x -> map (\y -> map (\(is, _) -> is) y) x) res
    let output = map (\x -> map (\y -> map (\(_, r) -> r) y) x) res
    in (index, output)

  let backward ((m,n): (i32, i32))(_:bool) (_:weights) (input:garbage) (error:error_in) : gradients =
    let (l_m, l_n) = (length input[0], length input[0,0])
    let width      = (l_n *n )
    let height     = (l_m * m)
    let total_elem = (height * width)
    let index_flat = map (\x -> flatten x) input
    let offsets    = map (\f -> map (\(i,j) -> j + i * width) f ) index_flat
    let error_flat = map (\x -> flatten x) error
    let retval     = map (\_ -> R.(i32 0)) (0..<(total_elem))
    let error'     = map2 (\o e -> scatter  (copy retval) o  e) offsets error_flat
    in (map (\x -> unflatten height width x) error', ())

  let update (_:t) (_:weights) (_:weights) = ()


  let layer ((m,n):(i32, i32)) (((),())) =
    (\w input -> forward (m,n) w input,
     backward (m,n),
     update,
      (()))

}

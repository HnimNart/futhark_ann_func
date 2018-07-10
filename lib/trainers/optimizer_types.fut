import "../nn_types"

module type trainer = {

  type t

  val train 'i 'w 'g 'e2 : NN ([]i) w ([][]t) g ([][]t) e2 t -> t -> ([]i) -> ([][]t) -> i32 -> ([][]t -> [][]t -> [][]t)
                             ->  NN ([]i) w ([][]t) g ([][]t) e2 t

}

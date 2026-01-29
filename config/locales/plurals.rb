{
  :ru => {
    :i18n => {
      :plural => {
        :keys => [:one, :few, :many, :other],
        :rule => lambda { |n|
          if n == 0
            :zero
          elsif ( ( n % 10 ) == 1 ) && ( ( n % 100 != 11 ) )
            :one
          elsif ( [2, 3, 4]. include?(n % 10) && ![12, 13, 14]. include?(n % 100) )
            :few
          else
            :many
          end
        }
      }
    }
  }
}
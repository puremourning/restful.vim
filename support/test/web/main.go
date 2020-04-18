package main
import (
	"encoding/json"
	"log"
	"net/http"
)

type RequestEat struct {
	Food string  `json:"food"`
	Drink string  `json:"drink"`
}

type Response struct {
	Message string  `json:"message"`
}

func main() {
    http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
			log.Printf( "Request: %v\n", r )
			data, _ := json.Marshal( Response{ Message: "test" } )
			r.Close = true
			w.WriteHeader( 200 )
			w.Header().Add( "Content-type", "application/json" )
			w.Write( data )
    })
    http.HandleFunc("/eat", func(w http.ResponseWriter, r *http.Request) {
			log.Printf( "Request: %v\n", r )
			var request RequestEat
			d := json.NewDecoder( r.Body )
			d.Decode( &request )

			data, _ := json.Marshal( Response{ Message: "eaten " + request.Food } )
			r.Close = true
			w.WriteHeader( 200 )
			w.Header().Add( "Content-type", "application/json" )
			w.Write( data )
    })
		log.Println( "Listening on localhost:25000" )
		log.Fatal(http.ListenAndServe(":25000", nil))
}

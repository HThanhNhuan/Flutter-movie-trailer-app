# API Service Documentation

This document provides documentation for the `ApiService` class, which is responsible for fetching data from The Movie Database (TMDb) API.

## Class: ApiService

Handles all network requests to the TMDb API.

### Private Helper Method: _getMovies

This is a private helper method used by other methods in the class to fetch a list of movies from a given URL.

-   **Parameters:**
    -   `url` (String): The full URL to fetch the movie list from.
-   **Returns:** `Future<List<Movie>>` - A list of `Movie` objects.
-   **Throws:** An `Exception` if the network request fails.

---

### Public Methods

#### getNowPlayingMovies

Fetches a list of movies that are currently playing in theaters.

-   **Endpoint:** `/movie/now_playing`
-   **Parameters:**
    -   `page` (int, optional): The page number to fetch. Defaults to `1`.
-   **Returns:** `Future<List<Movie>>` - A list of `Movie` objects.

#### getPopularMovies

Fetches a list of popular movies.

-   **Endpoint:** `/movie/popular`
-   **Parameters:**
    -   `page` (int, optional): The page number to fetch. Defaults to `1`.
-   **Returns:** `Future<List<Movie>>` - A list of `Movie` objects.

#### getTopRatedMovies

Fetches a list of top-rated movies.

-   **Endpoint:** `/movie/top_rated`
-   **Parameters:**
    -   `page` (int, optional): The page number to fetch. Defaults to `1`.
-   **Returns:** `Future<List<Movie>>` - A list of `Movie` objects.

#### getUpcomingMovies

Fetches a list of upcoming movies.

-   **Endpoint:** `/movie/upcoming`
-   **Parameters:**
    -   `page` (int, optional): The page number to fetch. Defaults to `1`.
-   **Returns:** `Future<List<Movie>>` - A list of `Movie` objects.

#### searchMovies

Searches for movies based on a query string.

-   **Endpoint:** `/search/movie`
-   **Parameters:**
    -   `query` (String): The search query.
-   **Returns:** `Future<List<Movie>>` - A list of `Movie` objects that match the query.

#### getMovieDetail

Fetches detailed information for a specific movie.

-   **Endpoint:** `/movie/{movieId}`
-   **Parameters:**
    -   `movieId` (int): The ID of the movie to fetch details for.
-   **Returns:** `Future<Movie>` - A `Movie` object containing detailed information.

#### getMovieCast

Fetches the cast list for a specific movie.

-   **Endpoint:** `/movie/{movieId}/credits`
-   **Parameters:**
    -   `movieId` (int): The ID of the movie.
-   **Returns:** `Future<List<Cast>>` - A list of `Cast` objects.

#### getActorDetails

Fetches the details for a specific actor.

-   **Endpoint:** `/person/{personId}`
-   **Parameters:**
    -   `personId` (int): The ID of the person (actor).
-   **Returns:** `Future<Actor>` - An `Actor` object.

#### getActorMovies

Fetches a list of movies a specific actor has been in.

-   **Endpoint:** `/person/{personId}/movie_credits`
-   **Parameters:**
    -   `personId` (int): The ID of the person (actor).
-   **Returns:** `Future<List<Movie>>` - A list of `Movie` objects.

#### getRecommendedMovies

Fetches a list of recommended movies for a given movie.

-   **Endpoint:** `/movie/{movieId}/recommendations`
-   **Parameters:**
    -   `movieId` (int): The ID of the movie.
-   **Returns:** `Future<List<Movie>>` - A list of recommended `Movie` objects.

#### getSimilarMovies

Fetches a list of similar movies for a given movie.

-   **Endpoint:** `/movie/{movieId}/similar`
-   **Parameters:**
    -   `movieId` (int): The ID of the movie.
-   **Returns:** `Future<List<Movie>>` - A list of similar `Movie` objects.

#### getMovieImages

Fetches a list of backdrop images for a specific movie.

-   **Endpoint:** `/movie/{movieId}/images`
-   **Parameters:**
    -   `movieId` (int): The ID of the movie.
-   **Returns:** `Future<List<MovieImage>>` - A list of `MovieImage` objects.

#### getMovieVideos

Fetches a list of videos (trailers, teasers) for a specific movie.

-   **Endpoint:** `/movie/{movieId}/videos`
-   **Parameters:**
    -   `movieId` (int): The ID of the movie.
-   **Returns:** `Future<List<Video>>` - A list of `Video` objects.

#### getMoviesByGenre

Fetches a list of movies belonging to a specific genre.

-   **Endpoint:** `/discover/movie`
-   **Parameters:**
    -   `genreId` (int): The ID of the genre.
    -   `page` (int, optional): The page number to fetch. Defaults to `1`.
-   **Returns:** `Future<List<Movie>>` - A list of `Movie` objects.

### Guess

This simple game showcases the facilities lua offers for random number generation.
It's the classic setup, where the computer "thinks" of a number, and the user is supposed to guess which one it is, the feedback offered being whether the guess was higher or lower than the target number.
If the value is correctly guessed, the game restarts with a new round.

#### Initialization

At the start, there are two steps of initializing. This is because part of it only needs to happen once, while the other part has to run at the start of every turn.

Running once:

```lua
-- initialize randomgenerator
math.randomseed(os.time())
-- set range
N = 100
-- declare the variable holding the target value
ntg = 0
```
Generating truly random numbers without outside input, turns out, is not an easy problem. In less critical use cases, like games, so-called pseudorandom numbers will do. For that to work, the generator needs to be initialized with a *seed*. This is not to say that it will not spit out arbitrary-looking values for us if we don't do this, but they would be the same between different runs of the program.
To use a different seed each time, a simple way is to just feed in the current time, which we can get from the system clock with `os.time()`. The details of how this works are irrelevant here, the important part is that each time it's a different value, so we'll get a different stream of pseudorandom numbers.

Running every time:

```lua
function init()
  ntg = math.random(N)
end
```
Once we have the seed set up, we can get a new random value between 1 and N by calling `math.random(N)`.

#### Gameplay

The rest is simple, continually prompt with a validated input which only accepts whole numbers, and determine where it stands in relation to the one being guessed at.

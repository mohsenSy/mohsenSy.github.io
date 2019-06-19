---
layout: post
title:  "Bootstrap with React"
date:   2019-06-17 01:02:00 +0300
categories: developer
summary: This tutorial describes how to use Bootstrap in React projects.
---

# Introduction

This is my second article about [React](https://reactjs.org) library for front end applications, the first one was a long
time ago, I wanted to create a second one quickly but I did not manage to write a new one as
I focused on my original job as Linux Systems Administrator but now I wanted to change my career
a little bit and work on web projects, this is very important for me to become a good DevOps
engineer in the future, I am already successful in Linux Systems and now the time to become
also successful in web applications so I can call my self a DevOps engineer in the future.

Here in this article we will build on the work from the tutorial found in React's website [here](https://reactjs.org/tutorial/tutorial.html)
and include some styling with additional features to the application.

We will include Bootstrap in our app and then improve it by ending the game when someone wins
or there is a draw, also we will only list history moves until the current step not until the
end so when we go back in history future moves are not displayed anymore.

# The initial app
Here we are not going to describe how to create the app from start to finish the tutorial on reactjs
website takes care of this, we will start with the already created app found in my github account
then build on that to add the features we discussed early on.

Clone the repository to your machine with this command and checkout the initial version then install
all dependencies

```
git clone https://github.com/mohsenSy/tictactoe-react.git
cd tictactoe-react
git checkout v0
npm i
```

To see the final version of this tutorial checkout the `v1` tag with this command

```
git checkout v1
```

We will list the tasks that will be completed in this article to get an idea about what we will
have when we finish:

* Distribute components code to multiple files
* Include Bootstrap
* Add style sheets to style our components
* Stop the game when it finishes in a win or a draw
* Show steps until current step only

# Components code organization
In our initial version found in tag `v0` we have all of the code for our react components in a single
file, this is fine for small projects but as our projects grow in size we cannot use a single file
for all of our components so it is advised to use multiple files one for each component, we will
put these files in a directory called `components` in the `src` directory.

Start by creating the new directory and create these two files in it: `Square.js` and `Board.js`
each one of them will hold code for Square and Board components respectively and also export
the component so we can import it from other directories.

Here are the contents for `Square.js`

```js
import React from 'react';

function Square(props) {
  return (
    <button
      onClick={props.onClick}
    >
    {props.value}
    </button>
  );
}

export default Square;
```

We defined Square as a function component rather than class component for simplicity, this component requires
two props to be defined:
* props.value: the value used to display in the square button.
* props.onClick: a function to be called when the button is clicked.

Now the Board component is class based and consists of 9 Square components, the code is shown bellow

```js
import React from 'react';
import Square from './Square';

class Board extends React.Component {
    renderSquare(i) {
      return (
          <Square
                value={this.props.squares[i]}
                onClick = {() => this.props.onClick(i)}
          />
        )
    }
  render() {
    return (
      <div>
        <div>
          {this.renderSquare(0)}
          {this.renderSquare(1)}
          {this.renderSquare(2)}
        </div>
        <div>
          {this.renderSquare(3)}
          {this.renderSquare(4)}
          {this.renderSquare(5)}
        </div>
        <div>
          {this.renderSquare(6)}
          {this.renderSquare(7)}
          {this.renderSquare(8)}
        </div>
      </div>
    );
  }
}

export default Board;
```

This component requires two props to be passed to it:
* props.squares: An array for the values of each square.
* props.onClick: A function that is called when each square is clicked.

In react we have the state stored in the parent component and then this state is passed
down to each child component using props, this is a best practice in react applications
that everyone is encouraged to follow.

Now we need to include the Board component in the root App component so we can use it
by adding this line to `Game.js` file:

```js
import Board from './components/Board';
```
And remove code for Square and Board components from line 4 to 46.

Run the development server with this command and keep it running to see changes in your
browser as you progress in this tutorial.

```
npm start
```

Now we have the components' code split into multiple files, we can include Bootstrap.

# Include Bootstrap

To include Bootstrap in a react application we can use the bootstrap npm package as follows

```
npm i bootstrap
```

Then we include bootstrap css file in `index.js` file by adding this line to the top of the file

```
import 'bootstrap/dist/css/bootstrap.min.css';
```

This file includes bootstrap CSS into reactjs application so we can use all bootstrap classes
in our HTMl code, let's test this by adding the `btn btn-primary` classes to our Square
component by modifying the button tag in the component and adding `className='btn btn-outline-primary'`
to it as follows:

```
<button className='btn btn-outline-primary'
```
Now we see that bootstrap class was applied correctly so we successfully includes bootstrap in our application

# Add style sheets to style our components
We can see that the size of our buttons changes when we click on them so we need to fix the size
of them to make it look better for this we will create a new style sheet and add our code to it.

Inside the src directory create a new directory called `css` and inside it create a file called
`square.css` with this content

```css
.square {
  width: 35px;
  height: 35px;
  margin: 10px
}
```

Now inside `Square.js` include the new CSS file using this import statement

```
import '../css/square.css';
```

Notice we used `..` to go one directory up from components folder where `Square.js` exists.

Finally add the new `square` class to the button element of the square and check the results.

Now add the container class to the outer div of the Game component defined in `Game.js` and reload
the page, the board is now displayed at the center of the page and looks a lot better.

The last style to add is the button classes for the steps list, add these two classes
to each button step in the list as follows:

```
className='btn btn-primary'
```

Now that look even better but wait a minute if you play the game the buttons in the steps
list almost overlap with each other so we need to add a margin to them, to do that create
a new file called `game.css` in the `css` directory and add this code to it

```css
.step {
  margin: 5px;
}
```

Include the new file in Game.js file with this line at the top
```js
import './css/game.css';
```
Then add the step class to the button and refresh and play the game, it looks really better right now :)

# Stop the game when it finishes or ends with a draw
To stop the game once it finishes we need to add a new attribute to the state object, let's
call it done the initial value is false, we can add it to the constructor of Game component.

```js
  done: false,
```

Then we add an if to the handleClick method that will ignore clicks when done is true

```js
if (!this.state.done) {
  // Add all previous code here
}
```
To finish this logic we must change the value of done to true when the game finishes and
there is a winner.

```js
if (calculateWinner(squares)) {
  this.setState({history: history.concat([{ squares: squares}]), stepNumber: history.length,  xIsNext: xIsNext, done: true,});
}
else {
  this.setState({history: history.concat([{ squares: squares}]), stepNumber: history.length,  xIsNext: xIsNext, done: false,});
}
```
We add this to the handleClick function.

Now we are dealing with the state when the game ended with a one but what about a draw
how can we test that? to stop the game when it happens.

A draw can be detected using this code

```js
const count = squares.filter((x) => {return x !== null}).length;
```
This code returns the number of squares whose value is not null, if this number equals 9
(the total number of squares) and there is no winner then this will be a draw, we set done
to true when the number is 9, this is the code for that

```js
if (calculateWinner(squares)) {
  this.setState({history: history.concat([{ squares: squares}]), stepNumber: history.length,  xIsNext: xIsNext, done: true});
}
else {
  const count = squares.filter((x) => {return x !== null}).length;
  if (count === 9) {
    this.setState({history: history.concat([{ squares: squares}]), stepNumber: history.length,  xIsNext: xIsNext, done: true});
  }
  else {
    this.setState({history: history.concat([{ squares: squares}]), stepNumber: history.length,  xIsNext: xIsNext, done: false});
  }
}
```
Good now we can check if the game ended with a draw and finish it as a draw but if you look
at the status line it says there is a next move for a player not the match ended with a draw
we can modify the logic there with the same way we modified the code in handleClick function

```js
let status;
if (winner) {
  status = "Winner: " + winner;
}
else {
  const count = current.squares.filter((x) => {return x !== null}).length;
  if (count === 9) {
    status = "This is a draw";
  }
  else {
    status = "Next player: " + (this.state.xIsNext ? 'X' : 'O');
  }
}
```
Now if you try a draw again it will say the match ended with a draw in the status line.

We are almost done now, only one task remains.

# Show steps until current step only
If we play the game and want to go back in time to a previous step we just click on the
step number and the board goes back to display the board at the selected step, but all
other future steps are shown too, let us not show them so always the current step is
located at the bottom of the list.

To achieve this we add this code to the map function on the history array in the
Game's component render method:

```js
if (move <= this.state.stepNumber) {
  return (
    <li key={move}>
      <button className="btn btn-primary step" onClick={() => this.jumpTo(move)}>{desc}</button>
    </li>
  )
}
return null;
```
We are checking if the move is less than ore equals current step number then display it
or return null if it is greater than current step number, so if we roll back in history
now all steps after the current step are not displayed anymore.

# Conclusion

In this tutorial we added on previous knowledge of react, learned how to include and use
bootstrap in react and achieved some tasks in the reactjs tutorial found [here](https://reactjs.org/tutorial/tutorial.html).

I hope you find the content useful for any comments or questions you can contact me
on my email address [mohsen47@hotmail.co.uk](mailto:mohsen47@hotmail.co.uk?subject=Bootstrap-with-React)

Stay tuned for more tutorials. :) :)

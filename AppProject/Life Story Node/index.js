// index.js
const express = require('express');
const multer = require('multer');
const upload = multer().single('image');
const fs = require('fs');
const path = require('path');
const app = express();
const port = 3000;
const ip = 'http://192.168.56.1:3000'

let posts = [];
loadPosts();


// Home route
app.get('/', (req, res) => {
	res.send('Welcome to the Home Page!');
});

// About route
app.get('/posts', (req, res) => {
	// sort post newest to oldest
	posts = posts.sort((a, b) => new Date(b.postDate) - new Date(a.postDate));

	return res.json(posts);
});

app.post('/post', (req, res) => {

	upload(req, res, (err) => {
		if (err) {
			return res.status(400).send('Bad Request');
		}

		const postId = posts.length;
		const username = req.query.username;
		const posterComment = req.query.comment;
		const image = req.file;

		console.log('Posting: ', 'username: ' + username, 'comment: ' + posterComment, 'image: ' + image)

		if (!username || !image) {
			return res.status(400).send('Bad Request');
		}

		const imageURL = `data:${image.mimetype};base64,${image.buffer.toString('base64')}`;

		const imagePath = path.join(__dirname, 'public', 'uploads', image.originalname);

		fs.writeFile(imagePath, image.buffer, (err) => {
			if (err) {
				console.error(err);
				return res.status(500).send('Internal Server Error');
			}

			posts.push({
				id: postId,
				imageURL: `${ip}/uploads/${image.originalname}`,
				likes: [],
				comments: [],
				username,
				postDate: new Date(),
			});

			commentPost(postId, username, posterComment);

			savePosts();

			return res.status(200).send('OK');
		});
	});
});

app.get('/posts/like', (req, res) => {
	const postId = req.query.postId;
	const username = req.query.username;

	if (!postId || !username) {
		return res.status(400).send('Bad Request');
	}

	if (!likePost(parseInt(postId), username)) {
		return res.status(400).send('Bad Request');
	}

	return res.status(200).send('OK');
});

app.get('/posts/comment', (req, res) => {
	const postId = req.query.postId;
	const username = req.query.username;
	const comment = req.query.comment;

	if (!postId || !username || !comment) {
		return res.status(400).send('Bad Request');
	}

	if (!commentPost(parseInt(postId), username, comment)) {
		return res.status(400).send('Bad Request');
	}

	return res.status(200).send('OK');
});

app.use(express.static(path.join(__dirname, 'public')));

function likePost(postId, username) {

	const post = posts.find((post) => post.id === postId);

	console.log('Liking post: ', 'postId: ' + postId, 'username: ' + username)

	if (!post) {
		return false;
	}

	const existingLike = post.likes.find((like) => like.username === username);
	if (existingLike) {
		// Unlike the post
		post.likes = post.likes.filter((like) => like !== existingLike);
		savePosts();
		return true;
	}

	post.likes.push({
		id: post.likes.length,
		username,
	});

	savePosts();

	return true;
}

function commentPost(postId, username, comment) {
	const post = posts.find((post) => post.id === postId);

	console.log('Commenting on post: ', 'postId: ' + postId, 'username: ' + username, 'comment: ' + comment)

	if (!post) {
		return false;
	}

	post.comments.push({
		id: post.comments.length,
		username,
		comment,
	});

	savePosts();

	return true;
}

/*
	Helper
*/
function savePosts() {
	try{
		fs.writeFile('posts.json', JSON.stringify(posts), (err) => {
			if (err) {
				console.error(err);
			}
		});
	} catch (err) {
		console.error(err);
	}
}

function loadPosts() {
	fs.readFile('posts.json', (err, data) => {
		if (err) {
			console.error(err);
			return;
		}

		posts = JSON.parse(data);
	});
}

// Start Server
app.listen(port, () => {
	console.log(`Server running at http://localhost:${port}`);
});

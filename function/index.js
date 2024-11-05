const admin = require('firebase-admin');
const { PubSub } = require('@google-cloud/pubsub');

// Initialize Firebase Admin SDK
admin.initializeApp();

// Initialize Pub/Sub client
const pubsub = new PubSub();

// Cloud Function triggered by Pub/Sub messages
exports.processOrder = async (message, context) => {
  try {
    // Decode the Pub/Sub message
    const orderData = JSON.parse(Buffer.from(message.data, 'base64').toString());

    // Initialize Firestore
    const db = admin.firestore();
    
    // Reference to the Firestore collection (Firestore creates the collection automatically if it doesn't exist)
    const orderRef = db.collection('incoming-orders').doc();  // Automatically generates a unique document ID

    // Write the order data to Firestore
    await orderRef.set(orderData);

    console.log('Order written to Firestore:', orderData);
    
    // Acknowledge the message so it is removed from the Pub/Sub queue
    message.ack();
  } catch (error) {
    console.error('Error processing order:', error);
    // If an error occurs, do not acknowledge the message so it can be retried
    message.nack();
  }
};

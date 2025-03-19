const port = 4000;
const express = require('express');
const nodemailer = require("nodemailer");
const mongoose  = require('mongoose');
const jwt = require('jsonwebtoken');
const multer = require('multer');
const cors = require('cors');
const path = require('path');

const Twilio = require("twilio");
const app = express();

const Razorpay = require('razorpay');
require('dotenv').config();
app.use(express.json());
app.use(cors());

//DB connection
mongoose.connect('mongodb+srv://narangnitin520:Dhp6JUd59tKRDTAo@cluster0.qeooz.mongodb.net/pharmacy');

var razorId = process.env.razorId;
var razorPass = process.env.razorPass;

let TwilioId = process.env.TwilioId;
let TwilioToken =process.env.TwilioToken;

const razorpay = new Razorpay({
    key_id: razorId,  
    key_secret: razorPass  
  });

const twilioClient = new Twilio(TwilioId, TwilioToken);


//Api Keypoint

app.get("/",(req,res) =>{
    res.send("Express App is Running");
})

//Image Stoarge Engine

const storage = multer.diskStorage({
    destination:'./upload/images',
    filename:(req,file,cb) =>{
        return cb(null,`${file.fieldname}_${Date.now()}${path.extname(file.originalname)}`)
    }
})

const upload = multer({storage:storage});

//Upload Endpoint for Images
app.use('/images',express.static('upload/images'))
app.post('/upload',upload.single('product'),(req,res) =>{
    res.json({
        sucess:1,
        image_url:`http://localhost:${port}/images/${req.file.filename}`
    })
})
//Schema for creating products 

const Product = mongoose.model("Product",{
    id:{
        type:Number,
        required:true
    },
    description:{
        type:String,
        required:true,
    },
    category:{
        type:String,
        required:true,
    },
    name:{
        type:String,
        required:true,
    },
    image:{
        type:String,
        required:true,
    },
    new_price:{
        type:Number,
        required:true
    },
    ingredients: {
        type: String,
        required: true,
    },
    date:{
        type:Date,
        default:Date.now
    },
    stock: {  
        type: Number,
        required: true,
         
    },
    original_price: { 
        type: Number, 
        required: true ,
        
    },
    available:{
        type:Boolean,
        default:true
    }
})

const Order = mongoose.model("Order", {
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "Users",
        required: true
    },
    items: {
        type: Object,  
        required: true
    },
    amount: {
        type: Number,
        required: true
    },
    payment_id: {
        type: String,
        required: true
    },
    order_id: {
        type: String,
        required: true
    },
    status: {
        type: String,
        enum: ['Order Placed', 'Dispatched', 'Delivered'],
        default: 'Order Placed'
    },
    date: {
        type: Date,
        default: Date.now
    }
});

//Schema for creating users modal

const Users = mongoose.model('Users',{
    name:{
        type:String,
    },
    email:{
        type:String,
        unique:true
    },
    password:{
        type:String,
    },
    cartData:{
        type:Object,
    },
    date:{
        type:Date,
        default:Date.now,
    }
})

const Review = mongoose.model("Review", {
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "Users",
        required: true
    },
    orderId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "Order",
        required: true
    },
    productId: {
        type: Number,  
        required: true
    },
    rating: {
        type: Number,  
        required: true,
        min: 1,
        max: 5
    },
    comment: {
        type: String,
        required: true
    },
    date: {
        type: Date,
        default: Date.now
    }
});


//Creating Endpoint for user register

app.post('/signup',async (req,res) =>{
    let check = await Users.findOne({email:req.body.email});
    if(check){
        return res.status(400).json({sucess:false,errors:"Existing user found with same email address"})
    }

    let cart = {};
    for (let i = 0; i < 300; i++) {
        cart[i]=0;
        
    }
    const user = new Users({
        name:req.body.username,
        email:req.body.email,
        password:req.body.password,
        cartData:cart
    })

    await user.save();

    const data = {
        user:{
            id:user.id
        }
    }

    const token = jwt.sign(data,'secert_ecom');
    res.json({sucess:true,token})
})
//Endpoint for User Login

app.post('/login',async (req,res) =>{
    let user = await Users.findOne({
        email:req.body.email
    })

    if(user){
        const passCompare = req.body.password === user.password;
        if(passCompare){
            const data ={
                user:{
                    id:user.id
                }
            }

            const token = jwt.sign(data,'secert_ecom');
            res.json({sucess:true,token})

        }
        else{
            res.json({sucess:false,errors:"Wrong Password"})
        }
    }
    else{
        res.json({sucess:false,errors:'Wrong Emailname'})
    }
})



//Api for adding to server
app.post('/addproduct',async (req,res) =>{
    let products = await Product.find({});
    let Id;
    if(products.length > 0){
        let last_product_array = products.slice(-1);
        let last_product = last_product_array[0];
        Id = last_product.id +1;
    }else{
        Id =1;
    }
    
    const product = new Product({
        id:Id,
        name:req.body.name,
        image: req.body.image,
        new_price:req.body.new_price,
        description:req.body.description,
        category:req.body.category,
        original_price:req.body.original_price,
        stock:req.body.stock,
        ingredients:req.body.ingredients
        
    });
    console.log(product);
    await product.save();
    console.log("Saved");
    res.json({
        sucess:true,

        name:req.body.name,
    })
    

})
//Api for removing product

app.post('/removeproduct',async(req,res) =>{
    await Product.findOneAndDelete({
        id:req.body.id
    });
    console.log("Removed");
    res.json({
        sucess:true,
        name:req.body.name
    })
    
})

//Api for getting all the products to the frontend 
app.get('/allproduct',async (req,res) =>{
    let products = await Product.find({})
    console.log("All product Fetched");
    res.send(products);
    
})

app.listen(port,(error) =>{
    if (!error) {
        
        
        console.log(`Server is Running on port ${port}`);
        
    } else {
        console.log(`Error : ${error}`);
        
    }
});




//Order id for razorPay


  app.post('/create-order', async (req, res) => {
    const amount = req.body.amount * 100;
    const phone = req.body.phone 
    
    if (!amount || !phone) {
                  return res.status(400).json({ error: "Amount and phone number are required" });
                }
        
        try {
            const order = await razorpay.orders.create({
                amount,
                currency: 'INR',
                receipt: `receipt_${Math.random().toString(36).substring(7)}`
            });
            res.json(order);
            console.log(phone);
        } catch (error) {
            res.status(500).send(error);
        }
    });

  
  
  // API to create a new order
//   app.post('/create-order', async (req, res) => {
//     const amount = req.body.amount * 100;  // Razorpay expects amount in paise
//     try {
//       const order = await razorpay.orders.create({
//         amount,
//         currency: 'INR',
//         receipt: `receipt_${Math.random().toString(36).substring(7)}`
//       });
//       res.json(order);
//     } catch (error) {
//       res.status(500).send(error);
//     }
//   });
    
//MiddleWare to fetch users
const fetchuser = async (req,res,next) =>{
    const token = req.header('auth-token');
    if (!token){
        res.status(401).send({errors:"Please authenticate using valid token"})
    }else{
        try {
            const data = jwt.verify(token,'secert_ecom');
            req.user = data.user;
            next();
        } catch (error) {
            res.status(401).send({errors:'Please authenticate '})
        }
    }
}

const updateOrderStatus = async (orderId) => {
    const delay = (min, max) => new Promise(res => setTimeout(res, Math.floor(Math.random() * (max - min + 1) + min) * 60000));

    await delay(1, 2);
    await Order.findByIdAndUpdate(orderId, { status: 'Dispatched' });

    await delay(2, 3);
    await Order.findByIdAndUpdate(orderId, { status: 'Delivered' });

    console.log(`Order ${orderId} delivered.`);
};

const sendPaymentEmail = async (email, orderDetails) => {
    try {
        // Configure Nodemailer transporter
        const transporter = nodemailer.createTransport({
            service: "Gmail",
            auth: {
                user: process.env.Gmailuser,  
                pass: process.env.Gmailpass 
            }
        });

        // Email message details
        const mailOptions = {
            from: process.env.Gmailuser, 
            to: email, 
            subject: "Order Confirmation - Your Payment Was Successful!",
            html: `
                <h2>Thank you for your purchase!</h2>
                <p>Your payment has been received successfully.</p>
                <h3>Order Details:</h3>
                <ul>
                    <li><strong>Order ID:</strong> ${orderDetails.order_id}</li>
                    <li><strong>Amount Paid:</strong> ₹${orderDetails.amount}</li>
                    <li><strong>Status:</strong> ${orderDetails.status}</li>
                    <li><strong>Date:</strong> ${new Date(orderDetails.date).toLocaleString()}</li>
                </ul>
                <p>We appreciate your business and hope you enjoy your purchase!</p>
            `
        };

        
        await transporter.sendMail(mailOptions);
        console.log("Payment confirmation email sent to", email);
    } catch (error) {
        console.error("Error sending email:", error);
    }
};


app.post("/razorpay-webhook", fetchuser, async (req, res) => {
    const { phone, payment_id, order_id, amount } = req.body;

    if (!phone || !payment_id || !order_id || !amount) {
        return res.status(400).json({ error: "Missing payment details" });
    }

    try {
        let user = await Users.findOne({ _id: req.user.id });
        if (!user) return res.status(404).json({ error: "User not found" });

        let cartItems = user.cartData;
        let productUpdates = [];

        for (let productId in cartItems) {
            if (cartItems[productId] > 0) {
                let product = await Product.findOne({ id: productId });
                if (!product) return res.status(400).json({ error: `Product ID ${productId} not found` });

                if (product.stock < cartItems[productId]) {
                    return res.status(400).json({ error: `Not enough stock for ${product.name}` });
                }

                productUpdates.push({
                    updateOne: {
                        filter: { id: productId },
                        update: { $inc: { stock: -cartItems[productId] } }
                    }
                });
            }
        }

        const newOrder = new Order({
            userId: user.id,
            items: cartItems,
            amount: amount,
            payment_id: payment_id,
            order_id: order_id,
            status: "Order Placed"
        });

        await newOrder.save();
        if (productUpdates.length > 0) await Product.bulkWrite(productUpdates);
        updateOrderStatus(newOrder._id)

        let emptyCart = {};
        for (let i = 0; i < 300; i++) emptyCart[i] = 0;
        await Users.findOneAndUpdate({ _id: req.user.id }, { cartData: emptyCart });

        await sendPaymentEmail(user.email, newOrder);


        await twilioClient.messages.create({
                            body: `Your order (ID: ${order_id}) of ₹${amount} is confirmed! Thank you for shopping.`,
                            from: process.env.senderPhone,
                            to: `+91${phone}`,
                        });

        console.log(`Order saved & stock updated. Email sent to ${user.email} and messsage to ${phone}`);

        res.status(200).json({
            success: true,
            message: "Order placed successfully",
            requestReview: true,  
            orderId: newOrder._id  
        });

    } catch (err) {
        console.error("Error processing order:", err);
        res.status(500).json({ error: "Server error" });
    }
});



app.get('/products/:id', async (req, res) => {
    try {
        const productId = req.params.id; 
        const product = await Product.findOne({ id: productId }); 
        
        if (!product) {
            return res.status(404).json({ message: 'Product not found' });
        }
        
        res.json(product); 
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Server error' });
    }
});

app.put('/product/:id', async (req, res) => {
    try {
        const { id } = req.params;  
        const { description, name, image, new_price, available,ingredients,stock,original_price } = req.body;  
        
        
        const updatedProduct = await Product.findOneAndUpdate(
            { id: id },  
            { description, name, image, new_price, available,ingredients,stock,original_price},  
            { new: true }  
        );
        
        if (!updatedProduct) {
            return res.status(404).send({ message: "Product not found" });
        }
        
        
        res.status(200).send(updatedProduct);
        console.log(`update ${id} ${updatedProduct}`);
        
    } catch (error) {
        console.error(error);
        res.status(500).send({ message: "Internal Server Error" });
    }
});

// Endpoint for storaging cart items in DB

app.post('/addtocart',fetchuser,async (req,res) =>{
    console.log("added" ,req.body.itemId);
    console.log(req.user);
    

    let userData = await Users.findOne({_id:req.user.id})
    console.log(userData);
    
    userData.cartData[req.body.itemId] += 1;
    await Users.findOneAndUpdate({_id:req.user.id},{cartData:userData.cartData});
    res.send("added");``
    
    console.log(req.body,req.user);
})

app.get('/myorders', fetchuser, async (req, res) => {
    try {
        let userId = req.user.id;  
        let orders = await Order.find({ userId }).sort({ date: -1 });  
        
        if (!orders.length) {
            return res.status(404).json({ success: false, message: "No orders found" });
        }

        res.json({ success: true, orders });
    } catch (error) {
        console.error("Error fetching user orders:", error);
        res.status(500).json({ success: false, message: "Server error" });
    }
});

app.get('/allorders', async (req, res) => {
    console.log("orders feteched through admin");
    
    try {
        let orders = await Order.find().sort({ createdAt: -1 }).lean();

        if (!orders.length) {
            return res.status(404).json({ success: false, message: "No orders found" });
        }

        res.json({ success: true, orders });
    } catch (error) {
        console.error(`[ERROR] /allorders - Error:`, error);
        res.status(500).json({ success: false, message: "Server error" });
    }
});


app.get('/order/:orderId', fetchuser, async (req, res) => {
    try {
        const order = await Order.findOne({ _id: req.params.orderId, userId: req.user.id });

        if (!order) {
            return res.status(404).json({ success: false, message: "Order not found" });
        }

        res.json({ success: true, order });
    } catch (error) {
        console.error("Error fetching order:", error);
        res.status(500).json({ success: false, message: "Server error" });
    }
});



app.get('/orders/:orderId', async (req, res) => {
    console.log("orderif through admin "+req.params.orderId);
    
    try {
        const { orderId } = req.params.orderId;

        // Validate orderId
        // if (!mongoose.Types.ObjectId.isValid(orderId)) {
        //     return res.status(400).json({ success: false, message: "Invalid order ID" });
        // }

        const order = await Order.findById(req.params.orderId);

        if (!order) {
            return res.status(404).json({ success: false, message: "Order not found" });
        }

        res.json({ success: true, data: order });
    } catch (error) {
        console.error("Error fetching order:", error.message);
        res.status(500).json({ success: false, message: "Server error" });
    }
});


//Endpoint for deleting cart from DB
app.post('/removefromcart',fetchuser,async (req,res) =>{
    console.log("removed", req.body.itemId);
    let userData = await Users.findOne({_id:req.user.id})
    if(userData.cartData[req.body.itemId]>0)
    userData.cartData[req.body.itemId] -= 1;
    await Users.findOneAndUpdate({_id:req.user.id},{cartData:userData.cartData});
    res.send("added");

    console.log(req.body,req.user);
})

//endpoint for cart object from DB 
app.post('/getcart',fetchuser,async(req,res) =>{
    console.log("Getcart");
    let userData = await Users.findOne({_id:req.user.id});
    res.json(userData.cartData);
    
})

app.post('/clearcart', fetchuser, async (req, res) => {
    try {
        let user = await Users.findOne({ _id: req.user.id });
        
        if (!user) {
            return res.status(404).json({ success: false, message: "User not found" });
        }
        
        // Reset the cartData object
        let emptyCart = {};
        for (let i = 0; i < 300; i++) {
            emptyCart[i] = 0;
        }
        
        await Users.findOneAndUpdate({ _id: req.user.id }, { cartData: emptyCart });
        
        res.json({ success: true, message: "Cart cleared successfully" });
    } catch (error) {
        console.error("Error clearing cart:", error);
        res.status(500).json({ success: false, message: "Server error" });
    }
});


app.post('/submit-review', fetchuser, async (req, res) => {
    try {
        const { orderId, productId, rating, comment } = req.body;

        if (!orderId || !productId || !rating || !comment) {
            return res.status(400).json({ error: "Missing review details" });
        }

        if (rating < 1 || rating > 5) {
            return res.status(400).json({ error: "Rating must be between 1 and 5" });
        }

        

        let order = await Order.findOne({ _id: orderId, userId: req.user.id });
        if (!order) {
            return res.status(404).json({ error: "Order not found or unauthorized" });
        }

        let newReview = new Review({
            userId: req.user.id,
            orderId,
            productId,
            rating,
            comment
        });

        await newReview.save();

        res.json({ success: true, message: "Review submitted successfully" });
    } catch (error) {
        console.error("Error submitting review:", error);
        res.status(500).json({ error: "Server error" });
    }
});

app.get('/reviews/:productId', async (req, res) => {
    try {
        const productId = parseInt(req.params.productId); // ✅ Convert to Number

        if (isNaN(productId)) {
            return res.status(400).json({ success: false, message: "Invalid product ID" });
        }

        const reviews = await Review.find({ productId }).populate("userId", "name");

        if (!reviews.length) {
            return res.status(404).json({ success: false, message: "No reviews found" });
        }

        res.json({ success: true, reviews });
    } catch (error) {
        console.error("Error fetching reviews:", error);
        res.status(500).json({ error: "Server error" });
    }
});

app.get("/reviews", async (req, res) => {
    try {
        const { userId } = req.query;
        let filter = {};
        
        if (userId) {
            filter.userId = userId;
        }
        
        const reviews = await Review.find(filter).populate("userId", "name email").populate("orderId", "orderNumber");
        
        res.status(200).json({ success: true, reviews });
    } catch (error) {
        res.status(500).json({ success: false, message: "Error fetching reviews", error: error.message });
    }
});

app.get("/review-report", async (req, res) => {
    try {
        const reviews = await Review.aggregate([
            {
                $group: {
                    _id: {
                        date: { $dateToString: { format: "%Y-%m-%d", date: "$date" } },
                        productId: "$productId"
                    },
                    totalReviews: { $sum: 1 },
                    averageRating: { $avg: "$rating" },
                    ratingsBreakdown: {
                        $push: {
                            rating: "$rating",
                            count: { $sum: 1 }
                        }
                    }
                }
            },
            { $sort: { "_id.date": -1 } }
        ]);

        res.json({ success: true, reports: reviews });
    } catch (error) {
        console.error("Error fetching review report:", error);
        res.status(500).json({ success: false, message: "Server Error" });
    }
});







// // order 

// const Order = mongoose.model("Order", {
//     user: { type: mongoose.Schema.Types.ObjectId, ref: 'Users' },
//     products: [{
//       productId: { type: mongoose.Schema.Types.ObjectId, ref: 'Product' },
//       quantity: { type: Number, required: true },
//       price: { type: Number, required: true },
//     }],
//     totalAmount: { type: Number, required: true },
//     status: { type: String, default: 'pending' },  // 'pending', 'paid', 'shipped', 'delivered'
//     date: { type: Date, default: Date.now },
//   });

  
//   // Create Order after payment success
// app.post('/create-order', fetchuser, async (req, res) => {
//     const { products, totalAmount } = req.body;  // Products added to cart and total amount paid
  
//     try {
//       // Create an order in the database
//       const order = new Order({
//         user: req.user.id,
//         products: products.map(item => ({
//           productId: item.productId,
//           quantity: item.quantity,
//           price: item.price,
//         })),
//         totalAmount,
//         status: 'paid',  // Mark order as paid
//       });
  
//       await order.save();
  
//       // Optionally, clear the user's cart after order is placed (if required)
//       await Users.findByIdAndUpdate(req.user.id, { cartData: getDefaultCart() });
  
//       res.json({ success: true, orderId: order._id });
//     } catch (error) {
//       console.error(error);
//       res.status(500).json({ success: false, errors: 'Error creating order' });
//     }
//   });

  
//   app.post('/verify-payment', async (req, res) => {
//     const { razorpay_order_id, razorpay_payment_id, razorpay_signature } = req.body;
//     const generated_signature = crypto.createHmac('sha256', 'bzKBHWR9mxDEwub9YbvIdGJ1')
//       .update(razorpay_order_id + "|" + razorpay_payment_id)
//       .digest('hex');
  
//     // Verify the signature
//     if (generated_signature !== razorpay_signature) {
//       return res.status(400).json({ success: false, message: 'Payment verification failed' });
//     }
  
//     try {
//       const order = await Order.findOne({ 'razorpay_order_id': razorpay_order_id });
//       if (order) {
//         order.status = 'paid';  // Update status to 'paid' after payment verification
//         await order.save();
//         res.json({ success: true, message: 'Payment verified successfully' });
//       } else {
//         res.status(404).json({ success: false, message: 'Order not found' });
//       }
//     } catch (error) {
//       console.error(error);
//       res.status(500).json({ success: false, message: 'Error verifying payment' });
//     }
//   });


app.get('/calculate-profit-pdf', async (req, res) => {
    try {
        const orders = await Order.find({ status: { $in: ["Delivered", "Dispatched", "Order Placed", "Paid"] } });

        let profitData = {}; // For PDF
        let dailyStats = {}; // For frontend graph

        for (let order of orders) {
            const orderDate = new Date(order.date);
            const day = orderDate.toISOString().split('T')[0]; // YYYY-MM-DD

            if (!dailyStats[day]) {
                dailyStats[day] = { date: day, profit: 0, totalSold: 0 };
            }

            for (let productId in order.items) {
                const quantity = order.items[productId];

                if (quantity > 0) {
                    const product = await Product.findOne({ id: productId });

                    if (product) {
                        const profitPerItem = product.new_price - product.original_price;
                        const totalProfit = profitPerItem * quantity;

                        const key = `${product.name}-${day}`;

                        if (!profitData[key]) {
                            profitData[key] = { 
                                productName: product.name, 
                                profit: 0,
                                quantitySold: 0,
                                date: day
                            };
                        }

                        profitData[key].profit += totalProfit;
                        profitData[key].quantitySold += quantity;

                        dailyStats[day].profit += totalProfit;
                        dailyStats[day].totalSold += quantity;
                    }
                }
            }
        }

        res.json({ 
            success: true, 
            profitData: Object.values(profitData), // For PDF
            dailyStats: Object.values(dailyStats) // For frontend graph
        });
    } catch (error) {
        console.error("Error calculating profit:", error);
        res.status(500).json({ success: false, message: "Server error" });
    }
});

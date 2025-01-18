import tensorflow as tf

# Load the .h5 model
model_path = '/Users/shweta/Crop Disease Recognition/crop_disease_model.h5'
model = tf.keras.models.load_model(model_path)

# Convert the model to TensorFlow Lite format
converter = tf.lite.TFLiteConverter.from_keras_model(model)
tflite_model = converter.convert()

# Save the converted model as .tflite
tflite_model_path = '/Users/shweta/Crop Disease Recognition/crop_disease_model.tflite'
with open(tflite_model_path, 'wb') as f:
    f.write(tflite_model)

print(f'Model converted successfully and saved to {tflite_model_path}')

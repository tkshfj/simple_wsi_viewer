# OpenSeadragon and OpenSlide

Combining **OpenSeadragon** and **OpenSlide** is a powerful way to visualize and interact with high-resolution whole-slide images (WSIs). Here’s a detailed explanation of how to set up this integration and leverage OpenSeadragon's filtering capabilities (e.g., `OpenSeadragonFiltering`).

---

## **Overview of Tools**
### **OpenSlide**
- OpenSlide is a C library for reading whole-slide image formats, commonly used in pathology and microscopy.
- It supports multiple formats, including SVS, NDPI, MRXS, and others.
- OpenSlide provides a server-side mechanism to extract image tiles from high-resolution images at various zoom levels.

### **OpenSeadragon**
- OpenSeadragon is a JavaScript library for creating interactive, zoomable image viewers.
- It works with deep-zoom image formats, like Deep Zoom Image (DZI), which are well-suited for large-scale images.

### **OpenSeadragonFiltering**
- `OpenSeadragonFiltering` is a plugin for OpenSeadragon that allows developers to apply custom image processing filters (e.g., brightness, contrast, color adjustments) dynamically on the client side.

---

## **Integration Workflow**

### **Step 1: Prepare Your Whole-Slide Image**
1. **Install OpenSlide:**
   - On a server (Linux/MacOS/Windows):
     ```bash
     sudo apt-get install openslide-tools  # Linux
     brew install openslide               # MacOS
     ```
2. **Generate Deep Zoom Image (DZI):**
   - Use OpenSlide's tools or Python bindings to convert the whole-slide image into DZI format:
     ```bash
     openslide-write-png example.svs level0 example_tile.png
     ```
   - Alternatively, use the Python bindings:
     ```python
     import openslide

     slide = openslide.OpenSlide('example.svs')
     slide.get_thumbnail((1024, 1024)).save('thumbnail.png')
     ```

### **Step 2: Set Up an OpenSeadragon Viewer**
1. Include OpenSeadragon in your project:
   ```html
   <script src="https://openseadragon.github.io/openseadragon/openseadragon.min.js"></script>
   ```
2. Create an HTML container for the viewer:
   ```html
   <div id="openseadragon" style="width: 800px; height: 600px;"></div>
   ```
3. Initialize OpenSeadragon:
   ```javascript
   const viewer = OpenSeadragon({
       id: "openseadragon",
       prefixUrl: "https://openseadragon.github.io/openseadragon/images/",
       tileSources: {
           Image: {
               xmlns: "http://schemas.microsoft.com/deepzoom/2008",
               Url: "/path/to/dzi/image/",
               Format: "jpg",
               Overlap: "1",
               TileSize: "256",
               Size: { Width: 10000, Height: 8000 }
           }
       }
   });
   ```

### **Step 3: Serve Tiles Dynamically**
- If your dataset is too large to pre-generate all tiles, set up a tile server:
  1. Install and configure a web server (e.g., Python's Flask or Django).
  2. Use OpenSlide to extract tiles dynamically based on zoom level and coordinates requested by OpenSeadragon.

   Example with Flask:
   ```python
   from flask import Flask, send_file
   import openslide

   app = Flask(__name__)
   slide = openslide.OpenSlide('example.svs')

   @app.route('/tile/<int:level>/<int:x>/<int:y>.jpeg')
   def get_tile(level, x, y):
       tile = slide.read_region((x * 256, y * 256), level, (256, 256))
       tile.save('tile.jpeg')
       return send_file('tile.jpeg', mimetype='image/jpeg')

   if __name__ == '__main__':
       app.run(debug=True)
   ```

   Update `tileSources` in OpenSeadragon to point to this dynamic endpoint.

---

## **Step 4: Apply OpenSeadragonFiltering**
The OpenSeadragonFiltering plugin lets you dynamically adjust visual filters like brightness, contrast, or apply custom shaders.

1. Include the plugin:
   ```html
   <script src="https://raw.githubusercontent.com/msalsbery/OpenSeadragonFiltering/main/openseadragon-filtering.js"></script>
   ```
2. Enable filtering in the viewer:
   ```javascript
   viewer.setFilterOptions({
       filters: [
           OpenSeadragon.Filters.BRIGHTNESS(1.2),  // Increase brightness by 20%
           OpenSeadragon.Filters.CONTRAST(1.5)    // Increase contrast by 50%
       ]
   });
   ```
3. Create custom filters (optional):
   - Define a custom shader to apply edge detection or other effects:
     ```javascript
     viewer.setFilterOptions({
         filters: [
             {
                 type: 'custom',
                 fragmentShader: `
                     uniform sampler2D u_image;
                     varying vec2 v_texCoord;

                     void main() {
                         vec4 color = texture2D(u_image, v_texCoord);
                         float gray = (color.r + color.g + color.b) / 3.0;
                         gl_FragColor = vec4(vec3(gray), 1.0);
                     }
                 `
             }
         ]
     });
     ```

---

## **Benefits of Using OpenSeadragonFiltering**
1. **Client-Side Flexibility:**
   - Apply real-time adjustments without reloading the image or contacting the server.
2. **Customization:**
   - Easily extend with custom shaders for unique visualization needs.
3. **Performance:**
   - Offloads processing to the client’s GPU, ensuring a smooth experience even with large datasets.

---

## **Example Use Cases**
- **Pathology:** Enhance or highlight specific regions in tissue samples.
- **Education:** Overlay annotations or dynamic color maps.
- **Research:** Apply dynamic filters for experimental analysis, like edge detection or intensity normalization.

By combining **OpenSeadragon** and **OpenSlide**, you can create a robust pipeline for interactive visualization of large-scale images while leveraging `OpenSeadragonFiltering` for real-time image processing.

Yes, you can adjust the **brightness** and **contrast** of an image in an OpenSeadragon viewer without using `OpenSeadragonFiltering` by manipulating the canvas rendering context or by applying CSS styles to the tiles or viewer container. Here's how you can do it:

---

### **1. Using CSS Filters**
You can apply brightness and contrast adjustments directly to the viewer's container using CSS. This is a simple and effective method for basic adjustments.

#### Code Example:
```html
<div id="openseadragon" style="width: 800px; height: 600px; filter: brightness(1.2) contrast(1.5);"></div>
```

#### Explanation:
- The `filter` CSS property allows you to adjust the image's brightness and contrast:
  - `brightness(1.2)` increases brightness by 20%.
  - `contrast(1.5)` increases contrast by 50%.
- Dynamically update these values using JavaScript if needed:
  ```javascript
  const viewerContainer = document.getElementById('openseadragon');
  viewerContainer.style.filter = `brightness(1.3) contrast(1.2)`;
  ```

---

### **2. Using Custom Tile Drawing**
Another approach is to customize how tiles are drawn onto the canvas by overriding the `tile-drawing` functionality. You can apply brightness and contrast adjustments manually using the `CanvasRenderingContext2D`.

#### Code Example:
```javascript
const viewer = OpenSeadragon({
    id: "openseadragon",
    prefixUrl: "https://openseadragon.github.io/openseadragon/images/",
    tileSources: "/path/to/dzi/image/"
});

// Hook into the tile-drawing process
viewer.addHandler("tile-drawn", function (event) {
    const context = event.context; // The 2D rendering context
    const canvas = context.canvas;
    const imageData = context.getImageData(0, 0, canvas.width, canvas.height);
    const data = imageData.data;

    // Adjust brightness and contrast
    const brightness = 1.2; // 1 = no change
    const contrast = 1.5; // 1 = no change
    for (let i = 0; i < data.length; i += 4) {
        data[i] = truncate(data[i] * brightness * contrast);     // Red
        data[i + 1] = truncate(data[i + 1] * brightness * contrast); // Green
        data[i + 2] = truncate(data[i + 2] * brightness * contrast); // Blue
    }

    // Update the canvas
    context.putImageData(imageData, 0, 0);
});

// Utility function to keep color values within range
function truncate(value) {
    return Math.min(255, Math.max(0, value));
}
```

#### Explanation:
- **Event Handler:**
  - The `tile-drawn` event fires whenever a tile is drawn.
  - The `event.context` provides access to the canvas rendering context.
- **Brightness & Contrast Adjustment:**
  - Modify the pixel data in the `ImageData` object.
  - Brightness multiplies the RGB values by a constant.
  - Contrast amplifies or reduces the difference from the average.

---

### **3. Using a Post-Rendering Hook**
OpenSeadragon allows you to add custom rendering operations after the tiles are drawn by using the `addHandler` method for `tile-loaded` or `canvas-drag` events.

#### Code Example:
```javascript
viewer.addHandler("update-viewport", function () {
    const context = viewer.drawer.context; // Access the main rendering context
    const canvas = context.canvas;
    const imageData = context.getImageData(0, 0, canvas.width, canvas.height);
    const data = imageData.data;

    // Apply brightness and contrast
    const brightness = 1.1;
    const contrast = 1.2;
    for (let i = 0; i < data.length; i += 4) {
        data[i] = truncate(data[i] * brightness * contrast);
        data[i + 1] = truncate(data[i + 1] * brightness * contrast);
        data[i + 2] = truncate(data[i + 2] * brightness * contrast);
    }

    // Update the canvas
    context.putImageData(imageData, 0, 0);
});
```

#### Explanation:
- This applies brightness and contrast to the entire canvas after the tiles have been drawn.
- Use `viewer.drawer.context` to manipulate the main rendering canvas.

---

### **Comparison of Methods**
| **Method**               | **Use Case**                                                                 | **Performance** | **Flexibility** |
|---------------------------|-----------------------------------------------------------------------------|----------------|----------------|
| CSS Filters              | Quick and simple adjustments for the entire viewer.                         | Fast           | Limited        |
| Custom Tile Drawing      | Adjust tiles individually for granular control.                             | Moderate       | High           |
| Post-Rendering Hook      | Apply adjustments to the final rendering of the entire viewer canvas.        | Moderate       | High           |

---

### **Best Approach**
- Use **CSS filters** for straightforward adjustments with minimal effort.
- Use **custom tile drawing** or **post-rendering hooks** for advanced scenarios, such as selective adjustments or when interacting with pixel data is required.

### **Report on Methods for Adjusting Brightness and Contrast in OpenSeadragon**

This report summarizes three methods for adjusting brightness and contrast in OpenSeadragon: **OpenSeadragonFiltering**, **Custom Tile Drawing**, and **Post-Rendering Hooks**. Each method has distinct characteristics and use cases.

---

### **1. OpenSeadragonFiltering**
**Overview:**
- OpenSeadragonFiltering is a plugin designed for dynamic image filtering.
- It allows for real-time adjustments such as brightness, contrast, and custom shaders on the client side.

**Key Features:**
- Built-in filters for brightness, contrast, and color manipulation.
- Support for custom shaders using WebGL, enabling advanced visual effects like edge detection.
- Filters are applied dynamically and efficiently using GPU acceleration.

**Use Cases:**
- Ideal for projects requiring frequent real-time adjustments without modifying the server or image source.
- Useful for enhancing visualization in research, education, or diagnostic tools.

**Strengths:**
- High performance due to GPU acceleration.
- Extensive flexibility with custom shaders.
- Minimal setup for basic filters.

**Limitations:**
- Requires inclusion of the OpenSeadragonFiltering plugin.
- Limited to scenarios where WebGL is supported.

---

### **2. Using Custom Tile Drawing**
**Overview:**
- Custom tile drawing involves overriding the default tile-rendering process to adjust brightness and contrast at the pixel level.
- Modifications are made to individual tiles before they are rendered on the canvas.

**Key Features:**
- Access to raw pixel data of tiles via the `CanvasRenderingContext2D`.
- Adjustments are applied during the tile rendering process using `ImageData`.

**Use Cases:**
- Suitable for scenarios where adjustments are needed per tile or based on tile-specific logic.
- Useful when integrating custom algorithms or applying selective adjustments.

**Strengths:**
- Fine-grained control over individual tiles.
- No external dependencies or plugins required.
- Compatible with all rendering environments, including non-WebGL setups.

**Limitations:**
- Requires manual implementation and pixel-level manipulation.
- Computationally expensive for large images or frequent updates.

---

### **3. Using a Post-Rendering Hook**
**Overview:**
- Post-rendering hooks allow for adjustments to the entire canvas after tiles have been drawn.
- Brightness and contrast adjustments are applied globally to the rendered output.

**Key Features:**
- Direct access to the final canvas using `viewer.drawer.context`.
- Modifies the entire viewport, making it a simpler approach than custom tile drawing.

**Use Cases:**
- Ideal for global adjustments applied uniformly to the entire viewer.
- Suitable for post-processing effects like brightness/contrast tweaks or overlays.

**Strengths:**
- Simple to implement for global adjustments.
- Works with the entire rendered image, ensuring uniform changes.

**Limitations:**
- Does not provide control at the tile level.
- Adjustments need to be recomputed with every viewport update, potentially impacting performance for large datasets.

---

### **Comparison Table**

| **Method**                | **Performance**  | **Flexibility**         | **Complexity** | **Best For**                                |
|---------------------------|------------------|-------------------------|----------------|---------------------------------------------|
| **OpenSeadragonFiltering** | High (GPU-based) | High (custom shaders)   | Low            | Dynamic, real-time adjustments.             |
| **Custom Tile Drawing**    | Moderate         | Very High               | High           | Tile-specific or algorithmic adjustments.   |
| **Post-Rendering Hook**    | Moderate         | Moderate (global only)  | Medium         | Global adjustments across the entire canvas.|

---

### **Recommendations**
1. **OpenSeadragonFiltering** is the preferred choice for projects requiring real-time interactivity or advanced visual effects.
2. **Custom Tile Drawing** should be used when precise, per-tile control is necessary or when external plugins cannot be used.
3. **Post-Rendering Hook** is ideal for simpler global adjustments or post-processing effects.

Each method has its place depending on the project's specific needs, the level of control required, and performance considerations.

### **GPU Acceleration in OpenSeadragonFiltering**

**OpenSeadragonFiltering** leverages **WebGL** for GPU acceleration to perform image processing tasks directly on the graphics hardware of the client device. This method significantly improves the performance of real-time visualizations and dynamic image adjustments compared to CPU-based approaches.

---

### **How GPU Acceleration Works in OpenSeadragonFiltering**
1. **WebGL Integration**:
   - The plugin utilizes **WebGL**, a JavaScript API for rendering 2D and 3D graphics in browsers.
   - WebGL provides direct access to the GPU, allowing for parallel processing of image data, which is much faster than sequential processing on the CPU.

2. **Fragment Shaders**:
   - At the core of GPU acceleration in OpenSeadragonFiltering are **fragment shaders**.
   - Fragment shaders are small programs that run on the GPU for each pixel or "fragment" of an image. They define how a pixel should appear after processing.
   - Developers can write custom fragment shaders in **GLSL (OpenGL Shading Language)** to apply specific effects, such as brightness, contrast, edge detection, or even complex transformations.

3. **Tile Processing Pipeline**:
   - Each image tile loaded by OpenSeadragon is sent to the GPU as a texture.
   - The fragment shader processes the texture, applying the desired effects.
   - The GPU outputs the processed texture, which is rendered on the viewer’s canvas.

---

### **Benefits of GPU Acceleration**
1. **Performance**:
   - GPUs are designed for high-throughput parallel computation, making them ideal for processing image data, where the same operation (e.g., brightness adjustment) is applied to millions of pixels simultaneously.
   - This ensures smooth interaction (e.g., panning, zooming) even when applying complex filters to large datasets.

2. **Real-Time Processing**:
   - Adjustments like brightness, contrast, or color mapping can be performed interactively, with immediate feedback.
   - Users can change parameters (e.g., slider for brightness) without noticeable delays.

3. **Resource Efficiency**:
   - By offloading image processing tasks to the GPU, the CPU is freed up for other operations, such as handling user interactions or network requests.

4. **Scalability**:
   - GPU acceleration allows for consistent performance, even with high-resolution images or a large number of tiles.

---

### **Example of GPU-Accelerated Processing**
Here is an example of a custom shader for **brightness and contrast adjustment**:

#### Fragment Shader Code (GLSL):
```glsl
uniform sampler2D u_image;    // The texture (image tile)
uniform float u_brightness;  // Brightness adjustment factor
uniform float u_contrast;    // Contrast adjustment factor
varying vec2 v_texCoord;     // Texture coordinate for the current fragment

void main() {
    vec4 color = texture2D(u_image, v_texCoord); // Get the original color
    color.rgb += u_brightness;                  // Adjust brightness
    color.rgb = ((color.rgb - 0.5) * u_contrast) + 0.5; // Adjust contrast
    gl_FragColor = color;                       // Output the new color
}
```

#### Integration with OpenSeadragonFiltering:
```javascript
viewer.setFilterOptions({
    filters: [
        {
            type: 'custom',
            fragmentShader: `
                uniform sampler2D u_image;
                uniform float u_brightness;
                uniform float u_contrast;
                varying vec2 v_texCoord;

                void main() {
                    vec4 color = texture2D(u_image, v_texCoord);
                    color.rgb += u_brightness;
                    color.rgb = ((color.rgb - 0.5) * u_contrast) + 0.5;
                    gl_FragColor = color;
                }
            `,
            uniforms: {
                u_brightness: 0.2,  // Adjust brightness
                u_contrast: 1.5    // Adjust contrast
            }
        }
    ]
});
```

---

### **Examples of Advanced GPU-Accelerated Filters**
1. **Edge Detection**:
   - Detect edges in images using algorithms like Sobel filters, implemented in fragment shaders.
2. **Color Mapping**:
   - Apply custom color maps to highlight specific data ranges, such as heatmaps in microscopy images.
3. **Gamma Correction**:
   - Adjust image gamma for enhanced visibility in specific regions.
4. **Custom Visualizations**:
   - Implement specialized effects like pseudocoloring for pathology applications.

---

### **Limitations and Considerations**
1. **Browser and Hardware Dependency**:
   - WebGL requires support from both the browser and the device’s GPU. Older devices or browsers without WebGL support cannot use these features.
   
2. **Development Complexity**:
   - Writing custom fragment shaders requires knowledge of GLSL, which might be challenging for developers unfamiliar with GPU programming.

3. **Debugging**:
   - Debugging shaders can be complex, as it involves understanding both the GPU pipeline and the interaction with the browser.

---

### **Conclusion**
GPU acceleration via WebGL in OpenSeadragonFiltering offers a highly efficient and flexible solution for real-time image processing. It is particularly advantageous for handling large datasets or interactive applications where performance is critical. By enabling developers to create custom fragment shaders, OpenSeadragonFiltering ensures that advanced visualization requirements can be met with minimal performance trade-offs.

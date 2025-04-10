# BestAI_DIP# BestAI_DIP

🏗️ DIP – Defect Inspector Pro

DIP is an iOS application that streamlines indoor structural defect inspections by integrating Augmented Reality (AR), Machine Learning, and 3D spatial mapping technologies. Built for iPadOS, the app leverages ARKit, RoomPlan, and a CoreML-integrated YOLOv8 object detection model to assist engineers and inspectors in identifying, documenting, and exporting structural defect data in real-world environments.

📸 Key Features

AR Environment Mapping
Uses ARKit and RoomPlan to generate an accurate 3D model of indoor spaces.
Real-Time Defect Detection
YOLOv8 model integrated via CoreML detects surface defects in real-time.
Spatial Defect Anchoring
Users can document defects by raycasting from 2D screen to 3D space and placing anchored markers.
Manual & Semi-Automatic Annotation
Includes both model-assisted and manual defect marking tools for maximum flexibility.
Image Snapshot & Metadata Logging
Captures ARFrame images with camera pose and stores all defect data in CSV format.
2D Floor Plan Rendering
Generates a 2D top-down view using SpriteKit for enhanced post-inspection review.
3D Model Post-Processing
Height normalization and object scaling ensures accurate export and visualization.


🛠️ Technologies Used

Swift + SwiftUI
ARKit / RealityKit / SceneKit
RoomPlan API (iOS 16+)
CoreML with YOLOv8
SpriteKit
CSV File I/O
Xcode 15 / iOS 17+


🚀 Getting Started
Prerequisites
macOS Ventura or later
Xcode 15+
iPad with LiDAR sensor (e.g., iPad Pro)
iOS 17+ device profile


Build Instructions
Clone the repository:
git clone https://github.com/yourusername/RCS.git
cd RCS
Open RCS.xcodeproj in Xcode.
Ensure your team and provisioning profile is set under Signing & Capabilities.
Plug in a supported iPad device and select it as the run target.
Build & Run!


📦 Exported Data

.csv – metadata and defect info
.usdz – RoomPlan 3D model
.png – AR snapshots of detected defects
.skarchive – optional SpriteKit top-down scene archive

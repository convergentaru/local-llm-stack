# Budget estimate — ROS 2 DIY robotic arm for LEGO

**Estimate date:** 2026-10-11  
**Currency:** EUR, approximate EU/NL budgeting, before confirming live seller prices.

## Summary

For a single small 6-DOF SO-ARM101 follower arm with a printed body, gripper, basic power/control electronics, existing Ubuntu PC and a basic webcam, plan on approximately **€200–350** if sourcing components and printing the body yourself or inexpensively. If the printed parts are outsourced and delivery costs are high, keep **€250–400** available.

This is a planning range, not a current guaranteed cart price. Servo prices, shipping, VAT and print service quotes change. LEGO snap-fit assembly is a harder task than simple pick-and-place; this budget only gets us a research arm, not a guaranteed LEGO-assembly machine.

## Option A — recommended small arm: SO-ARM101 follower

An upstream EU-oriented bill of materials reports approximately **€124.30 for one follower arm's non-printed components and basic items**, including six STS3215 servos, one motor-control board, power supply, USB cable, clamp and a screwdriver set. The same source estimates **€226.30 for the paired leader + follower setup**, excluding printed parts and cameras. Check the project's current BOM before ordering: [SO-ARM101 bill of materials reference](https://github.com/roboninecom/SO-ARM101).

| Item | Planning estimate | Notes |
|---|---:|---|
| Servos, control board, PSU, cable, clamp, basic tools | €125–160 | Reference BOM is ~€124; allow room for current price/shipping variance |
| 3D printed body | €15–35 if printed at home; ~€40–100 if ordered | Estimate depends on filament, failed prints, local service and part quality |
| Fasteners, inserts, replacement parts and wiring allowance | €10–30 | Contingency; check exact BOM before ordering |
| Simple USB camera | €20–50 | Optional for first manual pick-and-place; recommended for perception |
| Shipping/price contingency | €25–60 | Depends on sellers and sourcing |
| **Expected first single-arm build** | **~€200–350 self-printed; ~€250–400 outsourced printing** | PC already available |

The upstream table's component prices are indicative and may omit locally incurred taxes/shipping or printed pieces. Compare the current BOM and the exact servo variants before purchasing.

### ROS 2 support

Community packages exist for SO-ARM100/SO-ARM101 with robot descriptions, MoveIt configuration and hardware/simulation launch modes: [ros-physical-ai/ros2_so_arm](https://github.com/ros-physical-ai/ros2_so_arm). Another package implements a ROS 2 Control hardware interface for the six STS3215 joints: [renesas-rdk/so_arm101_ros2_control](https://github.com/renesas-rdk/so_arm101_ros2_control).

ROS 2, RViz, MoveIt and the controller software do not require a paid software license in this setup. The main cost is hardware and build time. Because these are community packages, verify the ROS 2 distro and hardware variant before assembly.

## Option B — paired leader/follower SO-ARM101 setup

A leader/follower arrangement can be valuable for teleoperation and collecting demonstrations to train/improve robotic policies. A reference BOM reports **~€226.30 for both arms' listed non-printed components and basic items**, excluding printed parts and cameras.

Budget approximately **€300–500** after printing, cameras/accessories, delivery and contingencies. The second arm is not necessary for a first ROS 2 pick-and-place experiment; it mainly adds a convenient teleoperation / demonstration interface.

## Option C — larger 6-axis Thor arm

[AngelLM/Thor](https://github.com/AngelLM/Thor) is an open-source, 3D-printed, six-axis arm built around NEMA17 steppers, printed gears and GT2 belts. The project describes a reach of about 625 mm, up to 750 g payload including the end-effector, and ROS 2 / MoveIt 2 integration; its published project description says hardware cost is below €350.

For budgeting, allow **~€400–600** unless the full current bill of materials and all required parts are already in hand. It is a larger design with more fabrication, mechanical assembly and calibration work than the compact SO-ARM101. Its reach/payload do not imply that it can accurately assemble LEGO snap-fits.


## Recommended purchase strategy for this project

**Recommended first build: one SO-ARM101 follower arm, simple parallel gripper, no second arm.** Keep the host computer as the existing Ubuntu machine and use a basic USB webcam. A practical target budget is **€250–350** if the printed parts can be made locally and delivery remains reasonable. Treat **€400** as a cautious ceiling for the first prototype if print service, shipping or replacement items cost more.

Buy in this order:

1. Confirm the current SO-ARM101 BOM and exact servo/controller versions.
2. Verify that the local Ubuntu setup can run the intended ROS 2 distribution and the community SO-ARM driver/MoveIt package.
3. Price the servos, controller, power supply, cables, fasteners and printed parts as one BOM before ordering.
4. Start without a second leader arm unless teleoperation/demonstration collection is explicitly part of the first experiment.
5. Add the camera and fixed lighting when moving from manual control to visual pick-and-place.

### Budget versus capability

| Budget bracket | Expected scope | Not promised |
|---|---|---|
| €200–350 | One compact printed arm, basic gripper, electronics, existing PC; optional basic camera depending on final bill | Reliable recognition of arbitrary LEGO parts or snap-fit assembly |
| €250–400 | Same first arm with outsourced printing / higher shipping contingency | Guaranteed precision manipulation |
| €300–500 | Two-arm leader/follower configuration for teleoperation/demonstrations | Better assembly accuracy without perception, calibration and trained control |
| €400–600 | Larger Thor-style six-axis printed arm, depending on BOM and sourcing | Automatic LEGO assembly out of the box |

All totals are planning estimates, not quotes from a single seller. Before purchasing, check taxes, shipping, exact servo model, included controller, power requirements and whether printed body parts are included. Do not order only on the basis of the headline price.

## What is not included

- Purchase of a 3D printer (printing service is used instead).
- New computer or single-board computer; assumes an existing Ubuntu machine runs ROS 2.
- Special force/torque sensor, tactile fingers, wrist camera, custom gripper, vision lighting or precision fixture.
- Significant tool upgrades, failed motor/printed-part replacements or custom PCB.
- Time spent assembling, calibrating, adapting drivers, configuring MoveIt and training a perception policy.

If a new host computer is needed, estimate it separately rather than treating it as part of the arm BOM.

## Important capability distinction

1. **Pick-and-place:** grab a known small object and place it somewhere — realistic first target.
2. **Part recognition and orientation:** identify multiple LEGO part IDs using camera + reference dataset and localise their pose — substantially harder.
3. **Snap-fit assembly:** align studs/tubes, apply controlled contact force and verify that pieces are connected without damage — much harder and not guaranteed by SO-ARM101 or Thor out of the box.

Start with fixed trays, one known part, one simple gripper and a limited workspace. Do not give Hermes direct motor control; it should request typed tasks while a ROS 2 controller enforces motion limits and a physical stop is available.

## Sources

- [SO-ARM101 component BOM reference](https://github.com/roboninecom/SO-ARM101)
- [ROS 2 descriptions/MoveIt/simulation for SO arms](https://github.com/ros-physical-ai/ros2_so_arm)
- [SO-ARM101 ROS 2 Control hardware interface](https://github.com/renesas-rdk/so_arm101_ros2_control)
- [AngelLM/Thor — 3D printed ROS 2 arm](https://github.com/AngelLM/Thor)

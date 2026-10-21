#include <ros/ros.h>
#include <std_msgs/Int32.h>
#include "add.h"

int main(int argc, char** argv) {
    ros::init(argc, argv, "add_node");
    ros::NodeHandle node;
    ros::Publisher publisher =
        node.advertise<std_msgs::Int32>("/lesson2/sum", 10);
    ros::Rate rate(1);

    while (ros::ok()) {
        std_msgs::Int32 message;
        message.data = add(1, 2);
        publisher.publish(message);
        ROS_INFO("sum = %d", message.data);
        rate.sleep();
    }
    return 0;
}

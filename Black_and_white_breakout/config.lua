application =
{
        content =
        {
            graphicsCompatibility = 1, --Old code needs this to cope with new Graphics2 framework
            width = 768,--default size for iPad2- not sure what sort of device should be min spec?
            height = 1024, --even though game is landscape this needs to indicate width/ height as portrait.
            scale = "letterbox", -- interesting to see what happens with 5S long screen
            fps = 60,
        },
}

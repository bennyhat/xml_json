defmodule XmlJson.AwsTest do
  use ExUnit.Case
  use Placebo

  doctest XmlJson.Aws

  describe "deserialize" do
    test "absorbs all but text in an element and does not preserve newlines" do
      xml = """
      <root>
      dog
      <stuff>5</stuff>
       </root>
      """

      assert {:ok, %{"root" => "dog"}} == XmlJson.Aws.deserialize(xml)
    end

    test "sets empty elements as nil" do
      xml = """
      <root></root>
      """

      assert {:ok, %{"root" => nil}} == XmlJson.Aws.deserialize(xml)
    end

    test "sets newline-only elements as nil" do
      xml = """
      <root>

      </root>
      """

      assert {:ok, %{"root" => nil}} == XmlJson.Aws.deserialize(xml)
    end

    test "turns singular members into a list" do
      xml = """
      <root>
        <member>
          <cat>dog</cat>
        </member>
      </root>
      """

      assert {:ok, %{"root" => [%{"cat" => "dog"}]}} == XmlJson.Aws.deserialize(xml)
    end

    test "turns multiple members into a list" do
      xml = """
      <root>
      <member>
        <cat>dog</cat>
      </member>
        <member>
          <cat>pig</cat>
        </member>
      </root>
      """

      assert {:ok, %{"root" => [%{"cat" => "dog"}, %{"cat" => "pig"}]}} == XmlJson.Aws.deserialize(xml)
    end

    test "turns a variety of member prefixes into a list" do
      xml = """
      <root>
        <animals>
          <member>
            <cat>dog</cat>
          </member>
          <member>
            <cat>pig</cat>
          </member>
        </animals>
        <people>
          <item>jeff</item>
          <item>balser</item>
        </people>
      </root>
      """

      assert {:ok, %{"root" => %{"animals" => [%{"cat" => "dog"}, %{"cat" => "pig"}], "people" => ["jeff", "balser"]}}} == XmlJson.Aws.deserialize(xml, list_element_names: ["member", "item"])
    end

    test "can handle a real-world example" do
      xml = """
      <DescribeListenersResponse xmlns="http://elasticloadbalancing.amazonaws.com/doc/2015-12-01/">
        <DescribeListenersResult>
          <Listeners>
            <member>
              <Port>443</Port>
              <Protocol>HTTPS</Protocol>
              <LoadBalancerArn>arn:aws:elasticloadbalancing:us-west-2:123456789012:loadbalancer/app/my-load-balancer/50dc6c495c0c9188</LoadBalancerArn>
              <ListenerArn>arn:aws:elasticloadbalancing:us-west-2:123456789012:listener/app/my-load-balancer/50dc6c495c0c9188/f2f7dc8efc522ab2</ListenerArn>
              <DefaultActions>
                <member>
                  <Type>forward</Type>
                  <TargetGroupArn>arn:aws:elasticloadbalancing:us-west-2:123456789012:targetgroup/my-targets/73e2d6bc24d8a067</TargetGroupArn>
                </member>
              </DefaultActions>
              <SslPolicy>ELBSecurityPolicy-2016-08</SslPolicy>
              <Certificates>
                <member>
                  <CertificateArn>arn:aws:acm:us-west-2:123456789012:certificate/68c11a12-39de-44dd-b329-fe64aEXAMPLE</CertificateArn>
                </member>
              </Certificates>
            </member>
          </Listeners>
        </DescribeListenersResult>
        <ResponseMetadata>
          <RequestId>18e470d3-f39c-11e5-a53c-67205c0d10fd</RequestId>
        </ResponseMetadata>
      </DescribeListenersResponse>
      """

      map = %{
        "DescribeListenersResponse" => %{
          "DescribeListenersResult" => %{
            "Listeners" => [
              %{
                "Port" => 443,
                "Protocol" => "HTTPS",
                "LoadBalancerArn" => "arn:aws:elasticloadbalancing:us-west-2:123456789012:loadbalancer/app/my-load-balancer/50dc6c495c0c9188",
                "ListenerArn" => "arn:aws:elasticloadbalancing:us-west-2:123456789012:listener/app/my-load-balancer/50dc6c495c0c9188/f2f7dc8efc522ab2",
                "DefaultActions" => [
                  %{
                    "Type" => "forward",
                    "TargetGroupArn" => "arn:aws:elasticloadbalancing:us-west-2:123456789012:targetgroup/my-targets/73e2d6bc24d8a067"
                  }
                ],
                "SslPolicy" => "ELBSecurityPolicy-2016-08",
                "Certificates" => [
                  %{
                    "CertificateArn" => "arn:aws:acm:us-west-2:123456789012:certificate/68c11a12-39de-44dd-b329-fe64aEXAMPLE"
                  }
                ]
              }
            ]
          },
          "ResponseMetadata" => %{
            "RequestId" => "18e470d3-f39c-11e5-a53c-67205c0d10fd"
          }

        }
      }
      assert {:ok, map} == XmlJson.Aws.deserialize(xml)
    end
  end
end
